#!/bin/bash

# rocm-sdk launcher for test application
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi
#AMD_LOG_LEVEL=1 HIP_VISIBLE_DEVICES=0 HIP_LAUNCH_BLOCKING=1 python pytorch_gpu_simple_test.py
python pytorch_audio_play_effects.py
