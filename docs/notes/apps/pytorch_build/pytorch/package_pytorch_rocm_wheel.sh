if [ -z "$1" ]; then
    install_dir_prefix_rocm=/opt/rocm
    echo "No rocm_root_directory_specified, using default: ${install_dir_prefix_rocm}"
else
    install_dir_prefix_rocm=${1}
    echo "using rocm_root_directory specified: ${install_dir_prefix_rocm}"
fi
source ${install_dir_prefix_rocm}/bin/env_rocm.sh
# ROCM_PATH required by pytorch configuration
export ROCM_PATH=${install_dir_prefix_rocm}
# ROCM_SOURCE_DIR required by pytorch/third_party/kineto to find ${ROCM_SOURCE_DIR}/include/roctracer/rocmtracer.h
export ROCM_SOURCE_DIR=${install_dir_prefix_rocm}
export CMAKE_PREFIX_PATH=${install_dir_prefix_rocm}
ROCM_PATH=${install_dir_prefix_rocm} ROCM_SOURCE_DIR=${install_dir_prefix_rocm} CMAKE_PREFIX_PATH=${install_dir_prefix_rocm} python setup.py bdist_wheel
