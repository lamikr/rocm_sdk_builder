# llama_cpp benchmark to check token generation speed
# provided by the jeroen-mostert in
# https://github.com/lamikr/rocm_sdk_builder/discussions/114
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi
#CUDA_VISIBLE_DEVICES=2
llama-cli -ngl 0 -m ~/models/Phi-3-mini-4k-instruct-q4.gguf -n 10 -f <(printf 'banana %0.s' {1..50}) -v 2>&1 | grep timings
