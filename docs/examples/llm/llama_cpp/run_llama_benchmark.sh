# llama_cpp benchmark to check token generation speed
# provided by the jeroen-mostert in
# https://github.com/lamikr/rocm_sdk_builder/discussions/114
if [ -z $ROCM_HOME ]; then
    echo "Error, make sure that you have executed"
    echo "    source  /opt/rocm_sdk_612/bin/env_rocm.sh"
    echo "before running this script"
    exit 1
fi
MODEL_FNAME=/opt/rocm_sdk_models/microsoft/Phi-3-mini-4k-instruct-q4.gguf
MODEL_DOWNLOAD_URL=https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/tree/main
#CUDA_VISIBLE_DEVICES=2
if [ ! -f $MODEL_FNAME ]; then
    echo "Could not find model file:"
    echo "    $MODEL_FNAME"
    echo "Try to download and install it from:"
    echo "    $MODEL_DOWNLOAD_URL"
fi
if [ -f $MODEL_FNAME ]; then
    PATH_TO_EXEC=$(which llama-cli)
    if [ -x "$PATH_TO_EXEC" ] ; then
	echo ""
        echo "llama-cli -no-cnv -ngl 0 -m $MODEL_FNAME -n 10 -f <(printf 'banana %0.s' {1..50})"
	echo ""
        llama-cli -no-cnv -ngl 0 -m $MODEL_FNAME -n 10 -f <(printf 'banana %0.s' {1..50}) -v 2>&1 | grep time
    else
	echo ""
	echo "Could not find llama-cli"
	echo "Have you build it with command?"
        echo "    ./babs.sh -b binfo/extra/ai_tools.blist"
	echo ""
    fi
fi
