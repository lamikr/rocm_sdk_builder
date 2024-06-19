export ROCM_PATH=${ROCM_HOME}
export HIP_HOME=${ROCM_HOME}
export LLVM_HOME=${ROCM_HOME}
export MAGMA_HOME=${ROCM_HOME}

export LD_LIBRARY_PATH=${ROCM_HOME}/lib64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_HOME}/lib:${LD_LIBRARY_PATH}

export DEVICE_LIB_PATH=${ROCM_HOME}/amdgcn/bitcode

# path to search OpenCL vendor-id icl files
# icd loader icd_linux.c from libOpenCL.so allow overriding
# the /etc/OpenCL/vendors/ with this variable
# note that the path must end with the slash "/" here, otherwise the
# implementation fails to open files it has scanned from directory.
export OCL_ICD_VENDORS=${ROCM_HOME}/etc/OpenCL/vendors/

# pythonpath is required at least by AMDMIGraphX pytorch module
export PYTHONPATH=${ROCM_HOME}/lib64:${ROCM_HOME}/lib:$PYTHONPATH

export PATH=${ROCM_HOME}/bin:${PATH}
