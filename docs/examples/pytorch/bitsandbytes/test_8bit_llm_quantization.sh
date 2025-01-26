#!/bin/bash

# rocm-sdk launcher for test application
# if test fails on AMD GPU, enable AMD_LOG_LEVEL and HIP_VISIBLE_DEVICES=0 variables
# to get traces to find the failing code part
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi

python test_8bit_llm_quantization.py
