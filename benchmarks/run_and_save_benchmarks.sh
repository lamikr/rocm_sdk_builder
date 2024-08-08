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
#AMD_LOG_LEVEL=1 HIP_VISIBLE_DEVICES=0 HIP_LAUNCH_BLOCKING=1

DATE_STR=`date '+%Y%m%d_%H%M%S'`;
echo "Timestamp for benchmark results: ${DATE_STR}"
FN_PYTORCH_CPU_VS_GPU_SIMPLE_RES="${DATE_STR}_cpu_vs_gpu_simple.txt"
FN_PYTORCH_DOT_PRODUCT_FLASH_RES="${DATE_STR}_pytorch_dot_products.txt"

echo "Saving to file: $FN_PYTORCH_CPU_VS_GPU_SIMPLE_RES"
python ../docs/examples/pytorch/pytorch_cpu_vs_gpu_simple_benchmark.py > ${FN_PYTORCH_CPU_VS_GPU_SIMPLE_RES}

echo "Saving to file: $FN_PYTORCH_DOT_PRODUCT_FLASH_RES"
python ../docs/examples/pytorch/flash_attention/flash_attention_dot_product_benchmark.py > ${FN_PYTORCH_DOT_PRODUCT_FLASH_RES}
