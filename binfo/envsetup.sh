#!/bin/bash
#
# License of this file: "THE COFFEEWARE LICENSE" (Revision 2).
# see coffeeware file in the root directory for details.

SDK_ROOT_DIR="$PWD"

# user configuration menu functionality
source binfo/user_config.sh

# allow enable doing some user specific extra actions before the build start
# like overriding the default INSTALL_DIR_PREFIX_SDK_ROOT directory location
if [[ -e "../envsetup_pre.sh" ]]; then
    source ../envsetup_pre.sh
fi

# check the linux distribution for the target triplet
export ROCM_TARGET_TRIPLED=x86_64-rocm-linux-gnu
if [[ -e "/etc/os-release" ]]; then
    source /etc/os-release
elif [[ -e "/etc/centos-release" ]]; then
    ID=$(cat /etc/centos-release | awk '{print tolower($1)}')
    VERSION_ID=$(cat /etc/centos-release | grep -oP '(?<=release )[^ ]*' | cut -d "." -f1)
fi
export ROCM_PYTHON_VERSION=v3.11.9
if [ ! -z ${ID+foo} ]; then
    case "${ID}" in
        mageia)
            # mageia linux 9 requires the triplet to be x86_64-mageia-linux
            # otherwise there are problem for hipcc to find internal include files when it calls gcc
            # https://github.com/lamikr/rocm_sdk_builder/issues/87
            export ROCM_TARGET_TRIPLED=x86_64-mageia-linux
            echo "Supported Linux distribution detected: ${ID}"
            true
            ;;
	ubuntu|linuxmint)
            case "$VERSION_ID" in
                21.*|22.04)
                    # ubuntu 22.04 would fail on AMDMIGraphX with python 3.11 to error:
		    # error: member access into incomplete type 'PyFrameObject' (aka '_frame')
                    export ROCM_PYTHON_VERSION=v3.10.14
		    true
                    ;;
                *)
		    ;;
            esac
	    ;;
	*)
	    ;;
    esac
fi
echo "ROCM_TARGET_TRIPLED: ${ROCM_TARGET_TRIPLED}"
echo "ROCM_PYTHON_VERSION: ${ROCM_PYTHON_VERSION}"

# set INSTALL_DIR_PREFIX_SDK_ROOT only if it not already set in the user environment variable or user_config.sh
INSTALL_DIR_PREFIX_SDK_ROOT="${INSTALL_DIR_PREFIX_SDK_ROOT:-/opt/rocm_sdk_${ROCM_MAJOR_VERSION}${ROCM_MINOR_VERSION}${ROCM_PATCH_VERSION}}"
export INSTALL_DIR_PREFIX_SDK_ROOT
echo "INSTALL_DIR_PREFIX_SDK_ROOT: $INSTALL_DIR_PREFIX_SDK_ROOT"

INSTALL_DIR_PREFIX_SDK_AI_MODELS="${INSTALL_DIR_PREFIX_SDK_AI_MODELS:-/opt/rocm_sdk_models}"
export INSTALL_DIR_PREFIX_SDK_AI_MODELS
echo "INSTALL_DIR_PREFIX_SDK_AI_MODELS: $INSTALL_DIR_PREFIX_SDK_AI_MODELS"

export ROCM_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}
export BUILD_RULE_ROOT_DIR=${SDK_ROOT_DIR}/binfo
export BUILD_SCRIPT_ROOT_DIR=${SDK_ROOT_DIR}/build
export PATCH_FILE_ROOT_DIR=${SDK_ROOT_DIR}/patches/${UPSTREAM_REPO_VERSION_TAG_DEFAULT}
export SDK_SRC_ROOT_DIR=${SDK_ROOT_DIR}/src_projects
export SDK_SRC_PYTHON_WHEEL_BACKUP_DIR=${SDK_ROOT_DIR}/packages/whl

if [ -e ${SDK_ROOT_DIR}/envsetup_pre.cfg ]; then
    source ${SDK_ROOT_DIR}/envsetup_pre.cfg
    echo "found ${SDK_ROOT_DIR}/envsetup_pre.cfg"
fi

if [ -e ${BUILD_RULE_ROOT_DIR}/binfo_list.sh ]; then
    source ${BUILD_RULE_ROOT_DIR}/binfo_list.sh
else
    echo "error, could not find file binfo.sh to load binfo build file list"
    exit 1
fi

if [ -e ${BUILD_SCRIPT_ROOT_DIR}/binfo_utils.sh ]; then
    source ${BUILD_SCRIPT_ROOT_DIR}/binfo_utils.sh
else
    echo "error, could not find file binfo.sh to load binfo build file list"
    exit 1
fi

if [ ! -v BUILD_CPU_COUNT_MIN ]; then
    export BUILD_CPU_COUNT_MIN=1
fi
if [ ! -v BUILD_CPU_COUNT_MAX ]; then
    export BUILD_CPU_COUNT_MAX=`nproc`
fi
RAM_MEM_GB_TOTAL=`free -g | grep -oP '\d+' | head -n 1`
if [ $RAM_MEM_GB_TOTAL -lt 32 ]; then
    RAM_MEM_GB_TOTAL=32
fi
if [ $BUILD_CPU_COUNT_MAX -lt 1 ]; then
    BUILD_CPU_COUNT_MAX=1
fi

RAM_MEM_GB_BY_CPU=$((${RAM_MEM_GB_TOTAL} / ${BUILD_CPU_COUNT_MAX}))

if [ ${BUILD_CPU_COUNT_MAX} -gt 16 ]; then
    if [ $RAM_MEM_GB_BY_CPU -gt 2 ]; then
        if [ ! -v BUILD_CPU_COUNT_DEFAULT ]; then
            export BUILD_CPU_COUNT_DEFAULT=$((7 * ${BUILD_CPU_COUNT_MAX} / 8))
        fi
        if [ ! -v BUILD_CPU_COUNT_MODERATE ]; then
            export BUILD_CPU_COUNT_MODERATE=$((3 * ${BUILD_CPU_COUNT_MAX} / 4))
        fi
        if [ ! -v BUILD_CPU_COUNT_SAFE ]; then
            # at least 5 GB per CPU
            export BUILD_CPU_COUNT_SAFE=$(($RAM_MEM_GB_TOTAL / 5))
        fi
        if [ $BUILD_CPU_COUNT_SAFE -gt $BUILD_CPU_COUNT_MODERATE ]; then
            export BUILD_CPU_COUNT_SAFE=$BUILD_CPU_COUNT_MODERATE
        fi
    else
        if [ ! -v BUILD_CPU_COUNT_DEFAULT ]; then
            export BUILD_CPU_COUNT_DEFAULT=$((3 * ${BUILD_CPU_COUNT_MAX} / 4))
        fi
        if [ ! -v BUILD_CPU_COUNT_MODERATE ]; then
            export BUILD_CPU_COUNT_MODERATE=$((5 * ${BUILD_CPU_COUNT_MAX} / 8))
        fi
        if [ ! -v BUILD_CPU_COUNT_SAFE ]; then
            # at least 5 GB per CPU
            export BUILD_CPU_COUNT_SAFE=$(($RAM_MEM_GB_TOTAL / 5))
        fi
        if [ $BUILD_CPU_COUNT_SAFE -gt $BUILD_CPU_COUNT_MODERATE ]; then
	    export BUILD_CPU_COUNT_SAFE=$BUILD_CPU_COUNT_MODERATE
        fi
    fi
else
    if [ $RAM_MEM_GB_BY_CPU -gt 2 ]; then
        # use by default total - 4 cpu's for building apps
        if [ ! -v BUILD_CPU_COUNT_DEFAULT ]; then
            export BUILD_CPU_COUNT_DEFAULT=$((7 * ${BUILD_CPU_COUNT_MAX} / 8))
        fi
        if [ ! -v BUILD_CPU_COUNT_MODERATE ]; then
            export BUILD_CPU_COUNT_MODERATE=$((3 * ${BUILD_CPU_COUNT_MAX} / 4))
        fi
        if [ ! -v BUILD_CPU_COUNT_SAFE ]; then
            export BUILD_CPU_COUNT_SAFE=$((${BUILD_CPU_COUNT_MAX} / 2))
        fi
    else
        # use by default total - 4 cpu's for building apps
        if [ ! -v BUILD_CPU_COUNT_DEFAULT ]; then
            export BUILD_CPU_COUNT_DEFAULT=$((3 * ${BUILD_CPU_COUNT_MAX} / 4))
        fi
        if [ ! -v BUILD_CPU_COUNT_MODERATE ]; then
            export BUILD_CPU_COUNT_MODERATE=$(( 5 * ${BUILD_CPU_COUNT_MAX} / 8))
        fi
        if [ ! -v BUILD_CPU_COUNT_SAFE ]; then
            export BUILD_CPU_COUNT_SAFE=$(($RAM_MEM_GB_TOTAL / 5))
        fi
    fi
fi
if [ $BUILD_CPU_COUNT_DEFAULT -le 1 ]; then
    export BUILD_CPU_COUNT_DEFAULT=1
fi
if [ $BUILD_CPU_COUNT_MODERATE -le 1 ]; then
    export BUILD_CPU_COUNT_MODERATE=1
fi
if [ $BUILD_CPU_COUNT_SAFE -le 1 ]; then
    export BUILD_CPU_COUNT_SAFE=1
fi

# BINFO_BUILD_CPU_COUNT defines the cpu count that build.sh will use for app
# each app's binfo file may change this value
if [ ! -v BINFO_BUILD_CPU_COUNT ]; then
    export BINFO_BUILD_CPU_COUNT=$BUILD_CPU_COUNT_DEFAULT
fi

#echo "RAM_MEM_GB_TOTAL: ${RAM_MEM_GB_TOTAL}"
#echo "RAM_MEM_GB_BY_CPU: ${RAM_MEM_GB_BY_CPU}"
#echo "BINFO_BUILD_CPU_COUNT: ${BINFO_BUILD_CPU_COUNT}"
#echo "BUILD_CPU_COUNT_MAX: ${BUILD_CPU_COUNT_MAX}"
#echo "BUILD_CPU_COUNT_DEFAULT: ${BUILD_CPU_COUNT_DEFAULT}"
#echo "BUILD_CPU_COUNT_MODERATE: ${BUILD_CPU_COUNT_MODERATE}"
#echo "BUILD_CPU_COUNT_SAFE: ${BUILD_CPU_COUNT_SAFE}"

#export ROCM_VERSION_STR="${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}"
export ROCM_LIBPATCH_VERSION=${ROCM_MAJOR_VERSION}0${ROCM_MINOR_VERSION}0${ROCM_PATCH_VERSION}
export ROCM_VERSION_STR=${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
export ROCM_VERSION_NMBR=$((10000 * ${ROCM_MAJOR_VERSION} + 100 * ${ROCM_MINOR_VERSION} + ${ROCM_PATCH_VERSION}))
export ROCM_VERSION_STR_ZEROED_NO_DOTS=${ROCM_VERSION_NMBR}
export CPACK_RPM_PACKAGE_RELEASE=01

export python=python

USER_CFG_FNAME='build_cfg.user'
unset USER_CONFIG_IS_OK
if [ -e ${USER_CFG_FNAME} ]; then
    while read CUR_GPU; do
        if [[ ${CUR_GPU} == gfx* ]]; then
            USER_CONFIG_IS_OK=1
        else
            echo "Error, invalid option in build_cfg.user file."
            echo "Build options must start with word gfx"
        fi
    done < "${USER_CFG_FNAME}"
fi

# Prompt user configuration if not found or invalid
if [ -z ${USER_CONFIG_IS_OK} ] || [ ! -e ${USER_CFG_FNAME} ]; then
    func_build_cfg_user
fi

# Set GPU targets
unset SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT
unset SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT
unset COMMA_SEPARATED_GPU_TARGET_LIST_DEFAULT
if [ -e ${USER_CFG_FNAME} ]; then
    while read CUR_GPU; do
        if [[ ${CUR_GPU} == gfx* ]]; then
            if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
                SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT=${CUR_GPU}
                SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT=${CUR_GPU}
                COMMA_SEPARATED_GPU_TARGET_LIST_DEFAULT=${CUR_GPU}
            else
                SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} ${CUR_GPU}"
                SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};${CUR_GPU}"
                COMMA_SEPARATED_GPU_TARGET_LIST_DEFAULT="${COMMA_SEPARATED_GPU_TARGET_LIST_DEFAULT},${CUR_GPU}"
            fi
        fi
    done < "${USER_CFG_FNAME}"
fi

# Check for selected GPUs
if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
    echo "Error, no GPU selected"
    echo "Enable at least one of the following variables in binfo/envsetup.sh file:"
    echo "    GPU_BUILD_AMD_VEGA_GFX902=1"
    echo "    GPU_BUILD_AMD_NAVI10_GFX1010=1"
    echo "    GPU_BUILD_AMD_NAVI14_GFX1012=1"
    echo "    GPU_BUILD_AMD_NAVI21_GFX1030=1"
    echo "    GPU_BUILD_AMD_REMBRANDT_GFX1035=1"
    exit -1
else
    echo "selected GPUs: ${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT}"
fi

# Format GPU target lists
SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="$( echo "$SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT" | sed 's/[[:space:]][[:space:]]*/;/g')"
LF_SEPARATED_GPU_TARGET_LIST_DEFAULT="$( echo "$SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT" | sed 's/[[:space:]][[:space:]]*/\n/g')"

#if [ ! -v SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
#    read -ra arr <<< "${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT}"
#    for a in ${arr[@]}; do
#        echo $a
#        if [ ! -v SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
#            SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT=$a
#        else
#            SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT=$SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT\;$a
#        fi
#    done
#fi

# Set build type variables
export CMAKE_BUILD_TYPE_DEBUG=Debug
export CMAKE_BUILD_TYPE_RELEASE=Release
export CMAKE_BUILD_TYPE_RELWITHDEBINFO=RelWithDebInfo

# Set default CMake configuration flags
export CMAKE_BUILD_TYPE_DEFAULT=${CMAKE_BUILD_TYPE_RELEASE}
export APP_CMAKE_CFG_FLAGS_DEBUG="-DCMAKE_C_FLAGS_DEBUG=-g3 -DCMAKE_CXX_FLAGS_DEBUG=-g3"
export APP_CMAKE_CFG_FLAGS_DEFAULT="-DCMAKE_INSTALL_LIBDIR=lib64"
if [ ${CMAKE_BUILD_TYPE_DEFAULT} == ${CMAKE_BUILD_TYPE_DEBUG} ] || [ ${CMAKE_BUILD_TYPE_DEFAULT} == ${CMAKE_BUILD_TYPE_RELWITHDEBINFO} ]; then
    export APP_CMAKE_CFG_FLAGS_DEFAULT="${APP_CMAKE_CFG_FLAGS_DEFAULT} ${APP_CMAKE_CFG_FLAGS_DEBUG}"
    echo "APP_CMAKE_CFG_FLAGS_DEFAULT: ${APP_CMAKE_CFG_FLAGS_DEFAULT}"
fi
# Set build root directory
export BUILD_ROOT_DIR=${SDK_ROOT_DIR}/builddir
#ROCM_DIR is needed at least by the rocminfo
#export ROCM_DIR=${INSTALL_DIR_PREFIX_SDK_ROOT}
export INSTALL_DIR_PREFIX_HIPCC=${INSTALL_DIR_PREFIX_SDK_ROOT}
export INSTALL_DIR_PREFIX_HIP_CLANG=${INSTALL_DIR_PREFIX_SDK_ROOT}
export INSTALL_DIR_PREFIX_HIP_LLVM=${INSTALL_DIR_PREFIX_SDK_ROOT}

export SDK_C_COMPILER_HIPCC=${INSTALL_DIR_PREFIX_HIPCC}/bin/hipcc
export SDK_CXX_COMPILER_HIPCC=${INSTALL_DIR_PREFIX_HIPCC}/bin/hipcc
export SDK_C_COMPILER_HIP_CLANG=${INSTALL_DIR_PREFIX_HIP_LLVM}/bin/clang
export SDK_CXX_COMPILER_HIP_CLANG=${INSTALL_DIR_PREFIX_HIP_LLVM}/bin/clang++

# Set SDK C++ compiler name based on selection
# Only choose one. SDK_CXX_COMPILER_NAME variable should not be used on any other scripts because
# these 3 names does not match with the names used by rocm for detecting the compiler.
# rocm is using only the following two names: "hcc" or "clang"
SDK_CXX_COMPILER_NAME="hipcc"
#SDK_CXX_COMPILER_NAME="hip_clang"

export SDK_PLATFORM_NAME_HIPCC="amd"
export SDK_PLATFORM_NAME_HIPCLANG="clang"

unset INSTALL_DIR_PREFIX_C_COMPILER

# Determine default SDK C and C++ compilers based on selection
if [ ${SDK_CXX_COMPILER_NAME} == "hipcc" ]; then
    export SDK_C_COMPILER_DEFAULT=${SDK_C_COMPILER_HIPCC}
    export SDK_CXX_COMPILER_DEFAULT=${SDK_CXX_COMPILER_HIPCC}
    export INSTALL_DIR_PREFIX_C_COMPILER=${INSTALL_DIR_PREFIX_HIPCC}
    export HIP_PLATFORM_DEFAULT=${SDK_PLATFORM_NAME_HIPCC}
fi
if [ ${SDK_CXX_COMPILER_NAME} == "hip_clang" ]; then
    export SDK_C_COMPILER_DEFAULT=${SDK_C_COMPILER_HIP_CLANG}
    export SDK_CXX_COMPILER_DEFAULT=${SDK_CXX_COMPILER_HIP_CLANG}
    export INSTALL_DIR_PREFIX_C_COMPILER=${INSTALL_DIR_PREFIX_HIP_CLANG}
    export HIP_PLATFORM_DEFAULT=${SDK_PLATFORM_NAME_HIPCLANG}
fi

# Set HIP_PATH
if [ -n ${INSTALL_DIR_PREFIX_C_COMPILER} ]; then
    export HIP_PATH_DEFAULT=${INSTALL_DIR_PREFIX_C_COMPILER}
else
    echo "no hip compiler defined"
    exit -1
fi

#HIP_PATH setup to /opt/rocm/hip breaks hipcc on rocm571
#export HIP_PATH=${HIP_PATH_DEFAULT}
# Set environment variables for HIP and ROCm paths
export HIP_PLATFORM=${HIP_PLATFORM_DEFAULT}
export HIPCC_VERBOSE=7

export LD_LIBRARY_PATH=/lib64:${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64:${INSTALL_DIR_PREFIX_SDK_ROOT}/lib:${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib
export PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/bin:$PATH

# Source post-configuration file if present
if [ -e ${SDK_ROOT_DIR}/envsetup_post.cfg ]; then
    echo "Found and executing ${SDK_ROOT_DIR}/envsetup_post.cfg"
    source ${SDK_ROOT_DIR}/envsetup_post.cfg
fi

# Set additional environment variables
export HIP_PLATFORM=hcc
export ROCM_DIR=${INSTALL_DIR_PREFIX_SDK_ROOT}
export HCC_HOME=${INSTALL_DIR_PREFIX_SDK_ROOT}/hcc
export HCC_PATH=${HCC_HOME}/bin
export HIP_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}
export ROCBLAS_HOME=${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas

export DEVICE_LIB_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/amdgcn/bitcode

export LD_LIBRARY_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCBLAS_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${HCC_HOME}/lib:${LD_LIBRARY_PATH}

export PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/hcc/bin:${PATH}
export PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/bin:${PATH}

# TRITON_HIP_LLD_PATH is needed by upstream triton in compiler.py
export TRITON_HIP_LLD_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/bin/ld.lld

# pythonpath is required at least by AMDMIGraphX pytorch module
# but if it is set, then the Tensile virtual env creation fails on rocBLAS
#export PYTHONPATH=${ROCM_HOME}/lib64:${ROCM_HOME}/lib:$PYTHONPATH

export LDFLAGS="-L${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64 -L${INSTALL_DIR_PREFIX_SDK_ROOT}/lib -L${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib -L${ROCBLAS_HOME}/lib -L${HCC_HOME}/lib"
export CFLAGS="-I${INSTALL_DIR_PREFIX_SDK_ROOT}/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocm_smi/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas/include"
export CPPFLAGS="-I${INSTALL_DIR_PREFIX_SDK_ROOT}/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocm_smi/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas/include"
export PKG_CONFIG_PATH="{INSTALL_DIR_PREFIX_SDK_ROOT}/lib64/pkgconfig:{INSTALL_DIR_PREFIX_SDK_ROOT}/lib/pkgconfig:{INSTALL_DIR_PREFIX_SDK_ROOT}/share/pkgconfig"

# Initialize binfo app list
func_binfo_utils__init_binfo_app_list

