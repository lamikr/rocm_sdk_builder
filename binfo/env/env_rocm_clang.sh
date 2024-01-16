export ROCM_DIR=/opt/rocm
export HIP_PATH=${ROCM_DIR}
export HCC_HOME=${ROCM_DIR}/hcc
export LD_LIBRARY_PATH=${HIP_PATH}/lib:${ROCM_DIR}/lib:${ROCM_DIR}/hsa/lib:${HCC_HOME}/lib
export PATH=${HIP_PATH}/bin:${PATH}
export PATH=${ROCM_DIR}/bin:${PATH}
export PATH=${ROCM_DIR}/hcc/bin:${PATH}
#export PATH=${ROCM_DIR}/llvm/bin:${PATH}
