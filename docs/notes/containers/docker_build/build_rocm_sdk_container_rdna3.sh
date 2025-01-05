export TMPFS=/opt/run
export TMPDIR=/opt/run
export ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED=docs/notes/containers/config/build_cfg_rdna3.user
podman build -t rocm_sdk_builder_rdna3 --build-arg ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED .
