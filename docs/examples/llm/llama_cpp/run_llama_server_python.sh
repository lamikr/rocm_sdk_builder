# simple pytorch python example to verify that gpu acceleration is enabled
# if test fails on AMD GPU, enable AMD_LOG_LEVEL and HIP_VISIBLE_DEVICES=0 variables
# to get traces to find the failing code part
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi

if [ ! -e  /opt/rocm_sdk_models/deepseek/DeepSeek-R1-Distill-Llama-8B-Q6_K.gguf ]; then
    mkdir -p /opt/rocm_sdk_models/deepseek
    cd /opt/rocm_sdk_models/deepseek
    echo "Download https://huggingface.co/bartowski/DeepSeek-R1-Distill-Llama-8B-GGUF/resolve/main/DeepSeek-R1-Distill-Llama-8B-Q6_K.gguf to directory /opt/rocm_sdk_models/deepseek"
    wget -c https://huggingface.co/bartowski/DeepSeek-R1-Distill-Llama-8B-GGUF/resolve/main/DeepSeek-R1-Distill-Llama-8B-Q6_K.gguf
fi

python -m llama_cpp.server --model /opt/rocm_sdk_models/deepseek/DeepSeek-R1-Distill-Llama-8B-Q6_K.gguf --n_ctx 16192 --api_key token-abc123
