# swithc first to users home dir inside docker image
cd
# then delete cache directories if they exist
if [ -d ./.triton/cache ]; then
    echo "removing directory ./.triton/cache"
    rm -rf ./.triton/cache
else
    echo "no need to cleanup ./.triton/cache"
fi
if [ -d ./.cache/bazel ]; then
    echo "removing directory ./.cache/bazel"
    rm -rf ./.cache/bazel
else
    echo "no need to cleanup ./.cache/bazel"
fi
if [ -d ./.cache/pip ]; then
    echo "removing directory ./.cache/pip"
    rm -rf ./.cache/pip
else
    echo "no need to cleanup ./.cache/pip"
fi
