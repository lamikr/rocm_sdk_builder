if [ -z "$1" ]; then
    install_dir_prefix_rocm=/opt/rocm
    echo "No rocm_root_directory_specified, using default: ${install_dir_prefix_rocm}"
else
    install_dir_prefix_rocm=${1}
    echo "using rocm_root_directory specified: ${install_dir_prefix_rocm}"
fi
source ${install_dir_prefix_rocm}/bin/env_rocm.sh
export CMAKE_PREFIX_PATH=${install_dir_prefix_rocm}
export CMAKE_INSTALL_PREFIX=${install_dir_prefix_rocm}
export CMAKE_C_COMPILER=${install_dir_prefix_rocm}/bin/hipcc
export CMAKE_CXX_COMPILER=${install_dir_prefix_rocm}/bin/hipcc
echo "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}"
ROCM_PATH=${install_dir_prefix_rocm} CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH} USE_ROCM=1 USE_FFMPEG=1 USE_OPENMP=1 CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} python setup.py install
