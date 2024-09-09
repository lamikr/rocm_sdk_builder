export ROCM_PATH=${ROCM_HOME}
export HIP_HOME=${ROCM_HOME}
export LLVM_HOME=${ROCM_HOME}
export MAGMA_HOME=${ROCM_HOME}

export LD_LIBRARY_PATH=${ROCM_HOME}/x86_64/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_HOME}/lib64:${LD_LIBRARY_PATH}

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
