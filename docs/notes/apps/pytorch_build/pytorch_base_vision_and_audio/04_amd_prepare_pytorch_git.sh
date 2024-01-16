source /opt/rocm/bin/env_rocm.sh
export CMAKE_PREFIX_PATH=/opt/rocm
cd pytorch
python tools/amd_build/build_amd.py
