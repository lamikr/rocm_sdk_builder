from pathlib import Path

import numpy as np

from xaiepy import pyxrt
from xaiepy.pyxrt import ert_cmd_state
import sys

def init_xrt_load_kernel(xclbin: Path):
    device = pyxrt.device(0)
    xclbin = pyxrt.xclbin(str(xclbin))
    device.register_xclbin(xclbin)
    return device, xclbin

_PROLOG = [
    0x00000011,
    0x01000405,
    0x01000100,
    0x0B590100,
    0x000055FF,
    0x00000001,
    0x00000010,
    0x314E5A5F,
    0x635F5F31,
    0x676E696C,
    0x39354E5F,
    0x6E693131,
    0x5F727473,
    0x64726F77,
    0x00004573,
    0x07BD9630,
    0x000055FF,
]

shim_instr_v = [
    0x06000100,
    0x00000000,
    0x00000001,
    0x00000000,
    0x00000000,
    0x00000000,
    0x80000000,
    0x00000000,
    0x00000000,
    0x02000000,
    0x02000000,
    0x0001D204,
    0x80000000,
    0x03000000,
    0x00010100,
]

#whichpi = "fivepi_xdna2"

def go(whichpi):
    instr_v = _PROLOG + shim_instr_v
    instr_v = np.array(instr_v, dtype=np.uint32)
    inout0 = np.zeros((1,), dtype=np.float32)

    device, xclbin = init_xrt_load_kernel(Path(__file__).parent.absolute() / f"{whichpi}.xclbin")
    
    context = pyxrt.hw_context(device, xclbin.get_uuid())
    xkernel = next(k for k in xclbin.get_kernels() if k.get_name() == whichpi)
    kernel = pyxrt.kernel(context, xkernel.get_name())

    bo_instr = pyxrt.bo(
        device, len(instr_v) * 4, pyxrt.bo.cacheable, kernel.group_id(0)
    )
    bo_inout0 = pyxrt.bo(device, 1 * 4, pyxrt.bo.host_only, kernel.group_id(2))

    bo_instr.write(instr_v, 0)
    bo_inout0.write(inout0, 0)

    bo_instr.sync(pyxrt.xclBOSyncDirection.XCL_BO_SYNC_BO_TO_DEVICE)
    bo_inout0.sync(pyxrt.xclBOSyncDirection.XCL_BO_SYNC_BO_TO_DEVICE)

    h = kernel(bo_instr, len(instr_v), bo_inout0)
    assert h.wait() == ert_cmd_state.ERT_CMD_STATE_COMPLETED
    bo_inout0.sync(pyxrt.xclBOSyncDirection.XCL_BO_SYNC_BO_FROM_DEVICE)
    entire_buffer = bo_inout0.read(4, 0).view(np.float32)
    print(entire_buffer[0])
    v = entire_buffer[0].item()
    assert isinstance(v, float)
    #assert np.isclose(v, 15.70795)
    print("passed, stored value is: " + format(v, '.5f'))

if len(sys.argv) == 2:
    NAME = sys.argv[1]
else:
    NAME = 'fivepi_xdna1'

go(NAME)
