# simple pytorch python example to verify that gpu acceleration is enabled
# if test fails on AMD GPU, enable AMD_LOG_LEVEL and HIP_VISIBLE_DEVICES=0 variables
# to get traces to find the failing code part

python pytorch_gpu_simple_test.py
#AMD_LOG_LEVEL=1 HIP_VISIBLE_DEVICES=0 HIP_LAUNCH_BLOCKING=1 python pytorch_gpu_simple_test.py
