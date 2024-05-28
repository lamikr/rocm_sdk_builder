#!/bin/bash

# License of this file: "THE COFFEEWARE LICENSE" (Revision 2).
# see coffeeware file in the root directory for details.

# Set SDK root directory
SDK_ROOT_DIR="$PWD"

# Source user configuration
source binfo/user_config.sh

# Set environment variables
export INSTALL_DIR_PREFIX_SDK_ROOT="/opt/rocm_sdk_${ROCM_MAJOR_VERSION}${ROCM_MINOR_VERSION}${ROCM_PATCH_VERSION}"
export ROCM_PATH="$INSTALL_DIR_PREFIX_SDK_ROOT"
export BUILD_RULE_ROOT_DIR="${SDK_ROOT_DIR}/binfo"
export BUILD_SCRIPT_ROOT_DIR="${SDK_ROOT_DIR}/build"
export PATCH_FILE_ROOT_DIR="${SDK_ROOT_DIR}/patches/${UPSTREAM_REPO_VERSION_TAG_DEFAULT}"
export SDK_SRC_ROOT_DIR="${SDK_ROOT_DIR}/src_projects"

# Source pre-setup configuration if available
if [ -e "${SDK_ROOT_DIR}/envsetup_pre.cfg" ]; then
    source "${SDK_ROOT_DIR}/envsetup_pre.cfg"
    echo "Found ${SDK_ROOT_DIR}/envsetup_pre.cfg"
fi

# Source necessary files
source "${BUILD_RULE_ROOT_DIR}/binfo_list.sh" || { echo "Error: could not find file binfo.sh to load binfo build file list"; exit 1; }
source "${BUILD_SCRIPT_ROOT_DIR}/binfo_utils.sh" || { echo "Error: could not find file binfo.sh to load binfo build file list"; exit 1; }

# Set default CPU counts
export BUILD_CPU_COUNT_MIN="${BUILD_CPU_COUNT_MIN:-1}"
export BUILD_CPU_COUNT_MAX="$(nproc)"
export BUILD_CPU_COUNT_DEFAULT="$(nproc --ignore=4)"
export BUILD_CPU_COUNT="${BUILD_CPU_COUNT_DEFAULT}"
export BUILD_CPU_COUNT_HALF="$((${BUILD_CPU_COUNT_MAX}/2))"
export BUILD_CPU_COUNT_TENSILE_SAFE="$((${BUILD_CPU_COUNT_DEFAULT}/2))"

# Set ROCM library version
export ROCM_LIBPATCH_VERSION="${ROCM_MAJOR_VERSION}0${ROCM_MINOR_VERSION}0${ROCM_PATCH_VERSION}"
export ROCM_VERSION_STR="${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}"
export ROCM_VERSION_NMBR="$(( 10000 * ROCM_MAJOR_VERSION + 100 * ROCM_MINOR_VERSION + ROCM_PATCH_VERSION ))"
export ROCM_VERSION_STR_ZEROED_NO_DOTS="${ROCM_VERSION_NMBR}"
export CPACK_RPM_PACKAGE_RELEASE="01"

# Set Python variable
export python="python"

# Check user configuration file
USER_CFG_FNAME='build_cfg.user'
if [ -e "${USER_CFG_FNAME}" ]; then
    while read CUR_GPU; do
        if [[ ${CUR_GPU} == gfx* ]]; then
            USER_CONFIG_IS_OK=1
        else
            echo "Error: invalid option in build_cfg.user file."
            echo "Build options must start with word gfx"
        fi
    done < "$USER_CFG_FNAME"
fi

# Prompt user configuration if not found or invalid
if [ -z ${USER_CONFIG_IS_OK} ] || [ ! -e ${USER_CFG_FNAME} ]; then
    func_build_cfg_user
fi

# Set GPU targets
SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT=""
SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT=""

if [ -e "${USER_CFG_FNAME}" ]; then
    while read CUR_GPU; do
        if [[ $CUR_GPU == gfx* ]]; then
            if [[ -z $SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]]; then
                SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="$CUR_GPU"
                SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="$CUR_GPU"
            else
                SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} ${CUR_GPU}"
                SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};${CUR_GPU}"
            fi
        fi
    done < "${USER_CFG_FNAME}"
fi

# Check for selected GPUs
if [[ -z $SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]]; then
    echo "Error: no GPU selected"
    echo "Enable at least one of the following variables in binfo/envsetup.sh file:"
    echo "    GPU_BUILD_AMD_VEGA_GFX902=1"
    echo "    GPU_BUILD_AMD_NAVI10_GFX1010=1"
    echo "    GPU_BUILD_AMD_NAVI14_GFX1012=1"
    echo "    GPU_BUILD_AMD_NAVI21_GFX1030=1"
    echo "    GPU_BUILD_AMD_REMBRANDT_GFX1035=1"
    exit -1
else
    echo "Selected GPUs: ${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT}"
fi

# Format GPU target lists
SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="$(echo "$SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT" | sed 's/[[:space:]][[:space:]]*/;/g')"
LF_SEPARATED_GPU_TARGET_LIST_DEFAULT="$(echo "$SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT" | sed 's/[[:space:]][[:space:]]*/\n/g')"

# Set build type variables
export CMAKE_BUILD_TYPE_DEBUG="Debug"
export CMAKE_BUILD_TYPE_RELEASE="Release"
export CMAKE_BUILD_TYPE_RELWITHDEBINFO="RelWithDebInfo"
export CMAKE_BUILD_TYPE_DEFAULT="${CMAKE_BUILD_TYPE_RELEASE}"

# Set default CMake configuration flags
export APP_CMAKE_CFG_FLAGS_DEBUG="-DCMAKE_C_FLAGS_DEBUG=-g3 -DCMAKE_CXX_FLAGS_DEBUG=-g3"
export APP_CMAKE_CFG_FLAGS_DEFAULT="-DCMAKE_INSTALL_LIBDIR=lib64"
if [ ${CMAKE_BUILD_TYPE_DEFAULT} == ${CMAKE_BUILD_TYPE_DEBUG} ] || [ ${CMAKE_BUILD_TYPE_DEFAULT} == ${CMAKE_BUILD_TYPE_RELWITHDEBINFO} ]; then
    export APP_CMAKE_CFG_FLAGS_DEFAULT="${APP_CMAKE_CFG_FLAGS_DEFAULT} ${APP_CMAKE_CFG_FLAGS_DEBUG}"
    echo "APP_CMAKE_CFG_FLAGS_DEFAULT: ${APP_CMAKE_CFG_FLAGS_DEFAULT}"
fi

# Set build root directory
export BUILD_ROOT_DIR="${SDK_ROOT_DIR}/builddir"

# Set ROCm and HIP compiler paths
export ROCM_DIR="$INSTALL_DIR_PREFIX_SDK_ROOT"
export INSTALL_DIR_PREFIX_HIPCC="$INSTALL_DIR_PREFIX_SDK_ROOT"
export INSTALL_DIR_PREFIX_HIP_CLANG="$INSTALL_DIR_PREFIX_SDK_ROOT"
export INSTALL_DIR_PREFIX_HIP_LLVM="$INSTALL_DIR_PREFIX_SDK_ROOT"

export SDK_C_COMPILER_HIPCC="${INSTALL_DIR_PREFIX_HIPCC}/bin/hipcc"
export SDK_CXX_COMPILER_HIPCC="${INSTALL_DIR_PREFIX_HIPCC}/bin/hipcc"
export SDK_C_COMPILER_HIP_CLANG="${INSTALL_DIR_PREFIX_HIP_LLVM}/bin/clang"
export SDK_CXX_COMPILER_HIP_CLANG="${INSTALL_DIR_PREFIX_HIP_LLVM}/bin/clang++"


# Set SDK C++ compiler name based on selection
#Only choose one. SDK_CXX_COMPILER_NAME variable should not be used on any other scripts because
# these 3 names does not match with the names used by rocm for detecting the compiler.
# rocm is using only the following two names: "hcc" or "clang"

SDK_CXX_COMPILER_NAME="hipcc" #Internal use only
#SDK_CXX_COMPILER_NAME="hip_clang" #Internal use only


export SDK_PLATFORM_NAME_HIPCC="amd"
export SDK_PLATFORM_NAME_HIPCLANG="clang"

# Determine default SDK C and C++ compilers based on selection
if [ "$SDK_CXX_COMPILER_NAME" = "hipcc" ]; then
    export SDK_C_COMPILER_DEFAULT="$SDK_C_COMPILER_HIPCC"
    export SDK_CXX_COMPILER_DEFAULT="$SDK_CXX_COMPILER_HIPCC"
    export INSTALL_DIR_PREFIX_C_COMPILER="$INSTALL_DIR_PREFIX_HIPCC"
    export HIP_PLATFORM_DEFAULT="$SDK_PLATFORM_NAME_HIPCC"
elif [ "$SDK_CXX_COMPILER_NAME" = "hip_clang" ]; then
    export SDK_C_COMPILER_DEFAULT="$SDK_C_COMPILER_HIP_CLANG"
    export SDK_CXX_COMPILER_DEFAULT="$SDK_CXX_COMPILER_HIP_CLANG"
    export INSTALL_DIR_PREFIX_C_COMPILER="$INSTALL_DIR_PREFIX_HIP_CLANG"
    export HIP_PLATFORM_DEFAULT="$SDK_PLATFORM_NAME_HIPCLANG"
fi

# Set HIP_PATH
if [ -n "$INSTALL_DIR_PREFIX_C_COMPILER" ]; then
    export HIP_PATH_DEFAULT="$INSTALL_DIR_PREFIX_C_COMPILER"
else
    echo "Error: No HIP compiler defined"
    exit 1
fi

# Set environment variables for HIP and ROCm paths
export HIP_PLATFORM="$HIP_PLATFORM_DEFAULT"
export HIPCC_VERBOSE=7
export LD_LIBRARY_PATH="/lib64:${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64:${INSTALL_DIR_PREFIX_SDK_ROOT}/lib:${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib:${ROCBLAS_HOME}/lib:${HCC_HOME}/lib:$LD_LIBRARY_PATH"
export PATH="${INSTALL_DIR_PREFIX_SDK_ROOT}/bin:${INSTALL_DIR_PREFIX_SDK_ROOT}/hcc/bin:$PATH"

# Source post-configuration file if present
if [ -e "${SDK_ROOT_DIR}/envsetup_post.cfg" ]; then
    echo "Found and executing ${SDK_ROOT_DIR}/envsetup_post.cfg"
    source "${SDK_ROOT_DIR}/envsetup_post.cfg"
fi

# Set additional environment variables
export HIP_PLATFORM=hcc
export ROCM_DIR=${INSTALL_DIR_PREFIX_SDK_ROOT}
export HCC_HOME=${INSTALL_DIR_PREFIX_SDK_ROOT}/hcc
export HCC_PATH=${HCC_HOME}/bin
export HIP_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}
export ROCBLAS_HOME=${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas
export DEVICE_LIB_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/amdgcn/bitcode
export LDFLAGS="-L${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64 -L${INSTALL_DIR_PREFIX_SDK_ROOT}/lib -L${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib -L${ROCBLAS_HOME}/lib -L${HCC_HOME}/lib"
export CFLAGS="-I${INSTALL_DIR_PREFIX_SDK_ROOT}/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocm_smi/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas/include"
export CPPFLAGS="-I${INSTALL_DIR_PREFIX_SDK_ROOT}/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocm_smi/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas/include"
export PKG_CONFIG_PATH="{INSTALL_DIR_PREFIX_SDK_ROOT}/lib64/pkgconfig:{INSTALL_DIR_PREFIX_SDK_ROOT}/lib/pkgconfig:{INSTALL_DIR_PREFIX_SDK_ROOT}/share/pkgconfig"

# Initialize binfo app list
func_binfo_utils__init_binfo_app_list