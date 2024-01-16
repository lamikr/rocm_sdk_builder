if [ -z "$1" ]; then
    install_dir_prefix_rocm=/opt/rocm
    echo "No rocm_root_directory_specified, using default: ${install_dir_prefix_rocm}"
else
    install_dir_prefix_rocm=${1}
    echo "using rocm_root_directory specified: ${install_dir_prefix_rocm}"
fi
if [ -z "$2" ]; then
    rocm_version_str=50701
    echo ""
    echo "Error, no rocm_root_directory_specified. For amd rocm version 5.7.1 call this script for example like:"
    echo "./build_pytorch_rocm.sh /opt/rocm 50701"
    echo ""
    exit 1
else
        rocm_version_str=${2}
        echo "using rocm_root_directory specified: ${install_dir_prefix_rocm}"
fi

source ${install_dir_prefix_rocm}/bin/env_rocm.sh
# ROCM_PATH required by pytorch configuration
export ROCM_PATH=${install_dir_prefix_rocm}
# ROCM_SOURCE_DIR required by pytorch/third_party/kineto to find ${ROCM_SOURCE_DIR}/include/roctracer/rocmtracer.h
export ROCM_SOURCE_DIR=${install_dir_prefix_rocm}
export CMAKE_PREFIX_PATH=${install_dir_prefix_rocm}
export ROCM_VERSION=${rocm_version_str}
echo "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}, ROCM_VERSION: ${ROCM_VERSION}"
CFLAGS="-DROCM_PATH=/opt/rocm_571 -DROCM_SOURCE_DIR=/opt/rocm_571 -DROCM_VERSION=${ROCM_VERSION} -DHIP_ROOT_DIR=${install_dir_prefix_rocm} -DUSE_ROCM=1"
CXXFLAGS="-DROCM_PATH=/opt/rocm_571 -DROCM_SOURCE_DIR=/opt/rocm_571 -DROCM_VERSION=${ROCM_VERSION} -DHIP_ROOT_DIR=${install_dir_prefix_rocm} -DUSE_ROCM=1"
ROCM_PATH=${install_dir_prefix_rocm} ROCM_SOURCE_DIR=${install_dir_prefix_rocm} CMAKE_PREFIX_PATH=${install_dir_prefix_rocm} ROCM_VERSION=${rocm_version_str} HIP_ROOT_DIR=${install_dir_prefix_rocm} USE_ROCM=1 python setup.py install
