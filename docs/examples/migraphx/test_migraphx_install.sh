# setup first the build environment with command
#
# source /opt/rocm_sdk_611/bin/env_rocm.sh
# 
# and then execute following to test migraphx installation
# details in: https://rocm.docs.amd.com/projects/radeon/en/latest/docs/install/install-migraphx.html
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi
migraphx-driver perf --model resnet50
