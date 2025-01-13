#! /usr/bin/env python

import argparse
import json
import logging
import platform
from pathlib import Path
import sys

from xaiepy import bootgen, xclbinutil
from xaiepy.cdo import (
    startCDOFileStream,
    FileHeader,
    configureHeader,
    endCurrentCDOFileStream,
    EnAXIdebug,
    setEndianness,
    Little_Endian,
)

logging.basicConfig(
    level=logging.DEBUG,
    format="%(message)s",
    datefmt="%H:%M:%S",
)

from xaiepy import (
    XAie_Config,
    XAie_BackendType,
    XAie_PartitionProp,
    XAie_DevInst,
    XAie_CfgInitialize,
    XAie_LocType,
    XAie_LoadElf,
    XAie_SetupPartitionConfig,
    XAie_UpdateNpiAddr,
    XAie_CoreReset,
    XAie_CoreUnreset,
    XAie_LockSetValue,
    XAie_Lock,
    XAie_DmaDescInit,
    XAie_DmaSetAddrLen,
    XAie_DmaEnableBd,
    XAie_DmaWriteBd,
    XAie_DmaChannelSetStartQueue,
    XAie_DmaChannelEnable,
    XAie_StrmConnCctEnable,
    XAie_CoreEnable,
    StrmSwPortType,
    XAie_EnableAieToShimDmaStrmPort,
    XAie_DmaDesc,
)

if platform.system() != "Windows":
    from xaiepy import XAie_ErrorHandlingInit

XAIE_DEV_GEN_AIEML = 2
XAIE_BASE_ADDR = 0x40000000
XAIE_COL_SHIFT = 25
XAIE_ROW_SHIFT = 20
XAIE_SHIM_ROW = 0
XAIE_MEM_TILE_ROW_START = 1
XAIE_PARTITION_BASE_ADDR = 0x0
XAIE_TRANSACTION_DISABLE_AUTO_FLUSH = 0b0
DDR_AIE_ADDR_OFFSET = 0x80000000

col = 0


def build_cdo(which_pi):
    tile_0_0 = XAie_LocType(0, col)
    tile_0_1 = XAie_LocType(1, col)
    tile_0_2 = XAie_LocType(2, col)

    configPtr = XAie_Config(
        XAIE_DEV_GEN_AIEML,
        XAIE_BASE_ADDR,
        XAIE_COL_SHIFT,
        XAIE_ROW_SHIFT,
        6,
        5,
        XAIE_SHIM_ROW,
        XAIE_MEM_TILE_ROW_START,
        1,
        (XAIE_MEM_TILE_ROW_START + 1),
        (6 - 1 - 1),
        XAie_PartitionProp(),
        XAie_BackendType.XAIE_IO_BACKEND_CDO,
    )

    devInst = XAie_DevInst()

    XAie_SetupPartitionConfig(devInst, 0, 1, 1)
    XAie_CfgInitialize(devInst, configPtr)
    XAie_UpdateNpiAddr(devInst, 0)

    EnAXIdebug()
    setEndianness(Little_Endian)
    cdo_fp = Path(__file__).parent.absolute() / f"{which_pi}_cdo.bin"
    startCDOFileStream(str(cdo_fp))
    FileHeader()

    if platform.system() != "Windows":
        XAie_ErrorHandlingInit(devInst)

    elf_path = Path(__file__).parent.absolute() / f"{which_pi}.elf"
    assert elf_path.exists()
    XAie_LoadElf(devInst, tile_0_2, str(elf_path), False)

    XAie_CoreReset(devInst, tile_0_2)
    XAie_CoreUnreset(devInst, tile_0_2)
    XAie_LockSetValue(devInst, tile_0_2, XAie_Lock(0, 1))
    XAie_LockSetValue(devInst, tile_0_2, XAie_Lock(1, 0))

    dmaTileBd = XAie_DmaDesc()
    XAie_DmaDescInit(devInst, dmaTileBd, tile_0_2)
    dmaTileBd.DmaMod.contents.SetLock(
        dmaTileBd, XAie_Lock(1, -1), XAie_Lock(0, 1), 1, 0
    )
    XAie_DmaSetAddrLen(dmaTileBd, 1024, 4)
    XAie_DmaEnableBd(dmaTileBd)
    XAie_DmaWriteBd(devInst, dmaTileBd, tile_0_2, 0)
    XAie_DmaChannelSetStartQueue(devInst, tile_0_2, 0, 1, 0, 1, 0)
    XAie_DmaChannelEnable(devInst, tile_0_2, 0, 1)

    XAie_StrmConnCctEnable(
        devInst, tile_0_0, StrmSwPortType.CTRL, 0, StrmSwPortType.SOUTH, 0
    )
    XAie_StrmConnCctEnable(
        devInst, tile_0_0, StrmSwPortType.NORTH, 0, StrmSwPortType.SOUTH, 2
    )
    XAie_StrmConnCctEnable(
        devInst, tile_0_1, StrmSwPortType.NORTH, 0, StrmSwPortType.SOUTH, 0
    )
    XAie_StrmConnCctEnable(
        devInst, tile_0_2, StrmSwPortType.DMA, 0, StrmSwPortType.SOUTH, 0
    )
    XAie_EnableAieToShimDmaStrmPort(devInst, tile_0_0, 2)
    XAie_CoreEnable(devInst, tile_0_2)

    configureHeader()
    endCurrentCDOFileStream()

    bif_fp = Path(__file__).parent.absolute() / f"{which_pi}.bif"
    with open(bif_fp, "w") as f:
        f.write(bootgen.emit_design_bif([cdo_fp]))

    pdi_fp = Path(__file__).parent.absolute() / f"{which_pi}.pdi"
    bootgen.make_design_pdi(str(bif_fp), str(pdi_fp))
    mem_top_json_fp = Path(__file__).parent.absolute() / f"{which_pi}_mem_topology.json"
    with open(mem_top_json_fp, "w") as f:
        json.dump(xclbinutil.mem_topology, f, indent=2)

    aie_part_json_fp = (
        Path(__file__).parent.absolute() / f"{which_pi}_aie_partition.json"
    )
    kernel_id = "0x902" if "two" in which_pi else "0x901"
    pdi_spec = xclbinutil.pdi_spec(pdi_fp, kernel_ids=[kernel_id])
    with open(aie_part_json_fp, "w") as f:
        json.dump(xclbinutil.emit_partition([pdi_spec], num_cols=1), f, indent=2)

    kernels_json_fp = Path(__file__).parent.absolute() / f"{which_pi}_kernel.json"
    kernel_spec = xclbinutil.kernel_spec(
        kernel_name=which_pi, kernel_id=kernel_id, buffer_args=["c0"]
    )
    with open(kernels_json_fp, "w") as f:
        json.dump(xclbinutil.emit_design_kernel_json([kernel_spec]), f, indent=2)

    pi_xclbin_fp = Path(__file__).parent.absolute() / f"{which_pi}.xclbin"
    xclbinutil.make_xclbin(
        str(mem_top_json_fp),
        str(aie_part_json_fp),
        str(kernels_json_fp),
        str(pi_xclbin_fp),
    )

if __name__ == "__main__":
    if len(sys.argv) == 2:
        NAME = sys.argv[1]
    else:
        NAME = 'fivepi_xdna1'
    build_cdo(NAME)
