#!/bin/bash

func_build_version_init() {
    local build_version_file="./binfo/build_version.sh"

    if [ -e "$build_version_file" ]; then
        source "$build_version_file"
    else
        echo "Error: Could not read $build_version_file"
        exit 1
    fi
}

func_envsetup_init() {
    local envsetup_file="./binfo/envsetup.sh"

    if [ -e "$envsetup_file" ]; then
        source "$envsetup_file"
    else
        echo "Error: Could not read $envsetup_file"
        exit 1
    fi
}

func_env_variables_print() {
    echo "SDK_CXX_COMPILER_DEFAULT: ${SDK_CXX_COMPILER_DEFAULT}"
    echo "HIP_PLATFORM_DEFAULT: ${HIP_PLATFORM_DEFAULT}"
    echo "HIP_PLATFORM: ${HIP_PLATFORM}"
    echo "HIP_PATH: ${HIP_PATH}"

    echo "SDK_ROOT_DIR: ${SDK_ROOT_DIR}"
    echo "SDK_SRC_ROOT_DIR: ${SDK_SRC_ROOT_DIR}"
    echo "BUILD_RULE_ROOT_DIR: ${BUILD_RULE_ROOT_DIR}"
    echo "PATCH_FILE_ROOT_DIR: ${PATCH_FILE_ROOT_DIR}"
    echo "BUILD_ROOT_DIR: ${BUILD_ROOT_DIR}"
    echo "INSTALL_DIR_PREFIX_SDK_ROOT: ${INSTALL_DIR_PREFIX_SDK_ROOT}"
    echo "INSTALL_DIR_PREFIX_HIPCC: ${INSTALL_DIR_PREFIX_HIPCC}"
    echo "INSTALL_DIR_PREFIX_HIP_CLANG: ${INSTALL_DIR_PREFIX_HIP_CLANG}"
    echo "INSTALL_DIR_PREFIX_C_COMPILER: ${INSTALL_DIR_PREFIX_C_COMPILER}"
    echo "INSTALL_DIR_PREFIX_HIP_LLVM: ${INSTALL_DIR_PREFIX_HIP_LLVM}"

    echo "SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT: ${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT}"
    echo "SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT: $SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT"
    echo "LF_SEPARATED_GPU_TARGET_LIST_DEFAULT: $LF_SEPARATED_GPU_TARGET_LIST_DEFAULT"
    echo "HIP_PATH_DEFAULT: ${HIP_PATH_DEFAULT}"
}

func_build_system_name_and_version_print() {
    echo "babs version: ${BABS_VERSION:-unknown}"
    echo "sdk version: ${ROCM_SDK_VERSION_INFO:-unknown}"
}

