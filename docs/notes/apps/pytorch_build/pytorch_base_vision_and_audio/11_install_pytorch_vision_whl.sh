source /opt/rocm/bin/env_rocm.sh
export CMAKE_PREFIX_PATH=/opt/rocm/pythonenv
pip install ./vision/dist/torchvision-0.15.0a0+6e203b4-cp38-cp38-linux_x86_64.whl
