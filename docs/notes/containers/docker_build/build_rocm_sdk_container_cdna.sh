export TMPFS=/opt/run
export TMPDIR=/opt/run
export ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED=docs/notes/containers/config/build_cfg_cdna.user
podman build -t rocm_sdk_builder_cdna --build-arg ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED .
