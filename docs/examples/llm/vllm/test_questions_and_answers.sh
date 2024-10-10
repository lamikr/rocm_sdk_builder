# simple pytorch python example to verify that gpu acceleration is enabled
# if test fails on AMD GPU, enable AMD_LOG_LEVEL and HIP_VISIBLE_DEVICES=0 variables
# to get traces to find the failing code part
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi

# for target device cuda is default
# rocm also works as vllm has this type of code to check it for example in setup.py:
#def _is_hip() -> bool:
#    return (VLLM_TARGET_DEVICE == "cuda"
#            or VLLM_TARGET_DEVICE == "rocm") and torch.version.hip is not None
export VLLM_TARGET_DEVICE="rocm"

# following is checked in envs.py
export XDG_CACHE_HOME=/opt/rocm_sdk_models/vllm
#export XDG_CONFIG_HOME=/opt/rocm_sdk_models/vllm

#AMD_LOG_LEVEL=1 HIP_VISIBLE_DEVICES=0 HIP_LAUNCH_BLOCKING=1
python questions_and_answers.py
