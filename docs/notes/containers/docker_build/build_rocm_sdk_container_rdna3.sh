#!/bin/bash

export PODMAN_IMG_NAME=rocm_sdk_builder_rdna3
export ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED=docs/notes/containers/config/build_cfg_rdna3.user

source ./rocman_common_parts_build_util.sh
func_build_rocm_container_image
