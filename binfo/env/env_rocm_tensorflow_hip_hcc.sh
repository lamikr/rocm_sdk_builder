export HIP_PLATFORM=hcc
export ROCM_DIR=/opt/rocm_571
export HCC_HOME=/opt/rocm_571/hcc
export HCC_PATH=${HCC_HOME}/bin
export HIP_PATH=${ROCM_DIR}
export HCC_HOME=${ROCM_DIR}/hcc
export ROCBLAS_HOME=${ROCM_DIR}/rocblas

export LD_LIBRARY_PATH=${ROCM_DIR}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_DIR}/hsa/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCBLAS_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${HCC_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${HIP_PATH}/lib:${LD_LIBRARY_PATH}

export PATH=${ROCM_DIR}/hcc/bin:${PATH}
export PATH=${ROCM_DIR}/bin:${PATH}
export PATH=${HCC_HOME}/bin:${PATH}
export PATH=${HIP_PATH}/bin:${PATH}
