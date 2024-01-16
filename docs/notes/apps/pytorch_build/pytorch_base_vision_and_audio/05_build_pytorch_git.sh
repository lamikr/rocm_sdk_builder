source /opt/rocm/bin/env_rocm.sh
export CMAKE_PREFIX_PATH=/opt/rocm
export ROCM_VERSION=50701
CFLAGS="-DROCM_VERSION=50701 -DHIP_ROOT_DIR=/opt/rocm -DUSE_ROCM=1"
cd pytorch
ROCM_VERSION=50701 HIP_ROOT_DIR=/opt/rocm USE_ROCM=1 python setup.py install
