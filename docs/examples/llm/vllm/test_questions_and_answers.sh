# simple pytorch python example to verify that gpu acceleration is enabled
# if test fails on AMD GPU, enable AMD_LOG_LEVEL and HIP_VISIBLE_DEVICES=0 variables
# to get traces to find the failing code part
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi
python questions_and_answers.py
#AMD_LOG_LEVEL=1 HIP_VISIBLE_DEVICES=0 HIP_LAUNCH_BLOCKING=1 python questions_and_answers.py
