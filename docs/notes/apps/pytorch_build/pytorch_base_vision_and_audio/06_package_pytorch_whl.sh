source /opt/rocm/bin/env_rocm.sh
export CMAKE_PREFIX_PATH=/opt/rocm/pythonenv
cd pytorch/
python setup.py bdist_wheel

