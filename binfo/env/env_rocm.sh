export ROCM_HOME=/opt/rocm_571
export LLVM_HOME=${ROCM_HOME}/llvm
export HIP_HOME=${ROCM_HOME}

export LD_LIBRARY_PATH=${HIP_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${LLVM_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_HOME}/lib64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCM_HOME}/lib:${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH=${ROCM_HOME}/python38/lib:${LD_LIBRARY_PATH}

export PATH=${HIP_HOME}/bin:${PATH}
export PATH=${LLVM_HOME}/bin:${PATH}
export PATH=${ROCM_HOME}/bin:${PATH}
#export PATH=${ROCM_HOME}/python38/bin:${PATH}
