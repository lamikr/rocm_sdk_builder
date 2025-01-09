export ROCM_PATH=${ROCM_HOME}
export HIP_HOME=${ROCM_HOME}
export LLVM_HOME=${ROCM_HOME}
export MAGMA_HOME=${ROCM_HOME}

export LD_LIBRARY_PATH=${ROCM_HOME}/x86_64/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_HOME}/lib64:${LD_LIBRARY_PATH}

#set mpicc openmpi compiler wrapper to use hipcc a compiler by default
OMPI_CC=${ROCM_HOME}/bin/hipcc
OMPI_CXX=${ROCM_HOME}/bin/hipcc
#OMPI_CC=${ROCM_HOME}/bin/clang
#OMPI_CXX=${ROCM_HOME}/bin/clang++

# list of nodes available for openmpi/slurm. Test with command: scontrol show hostnames
export SLURM_NODELIST=localhost

#omnitrace-avail needs ROCP_METRICS
export ROCP_METRICS=${ROCM_HOME}/lib64/rocprofiler/metrics.xml

export DEVICE_LIB_PATH=${ROCM_HOME}/amdgcn/bitcode

# path to search OpenCL vendor-id icl files
# icd loader icd_linux.c from libOpenCL.so allow overriding
# the /etc/OpenCL/vendors/ with this variable
# note that the path must end with the slash "/" here, otherwise the
# implementation fails to open files it has scanned from directory.
export OCL_ICD_VENDORS=${ROCM_HOME}/etc/OpenCL/vendors/

# pythonpath is required at least by AMDMIGraphX pytorch module
export PYTHONPATH=${ROCM_HOME}/lib64:${ROCM_HOME}/lib:$PYTHONPATH

# TRITON_HIP_LLD_PATH is needed by upstream triton in compiler.py
export TRITON_HIP_LLD_PATH=${ROCM_HOME}/bin/ld.lld

export PATH=${ROCM_HOME}/bin:${PATH}

# xdna xrt runtime env
export XILINX_XRT=${ROCM_HOME}/apps/aie/xrt

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${XILINX_XRT}/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ROCM_HOME}/apps/aie/lib

export PATH=${PATH}:${XILINX_XRT}/bin
export PATH=${PATH}:${ROCM_HOME}/apps/aie/bin
