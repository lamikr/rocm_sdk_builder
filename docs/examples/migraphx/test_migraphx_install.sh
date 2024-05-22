# setup first the build environment with command
#
# source /opt/rocm_sdk_611/bin/env_rocm.sh
# 
# and then execute following to test migraphx installation
# details in: https://rocm.docs.amd.com/projects/radeon/en/latest/docs/install/install-migraphx.html
migraphx-driver perf --model resnet50
