source /opt/rocm/bin/env_rocm.sh
export CMAKE_PREFIX_PATH=/opt/rocm/pythonenv
cd vision
FORCE_CUDA=1 TORCHVISION_USE_NVJPEG=0 TORCHVISION_USE_VIDEO_CODEC=0 CC=gcc CXX=g++ python setup.py bdist_wheel

