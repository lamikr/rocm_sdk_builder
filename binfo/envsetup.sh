#!/bin/bash
#
# License of this file: "THE COFFEEWARE LICENSE" (Revision 2).
# see coffeeware file in the root directory for details.

# Select below one or more AMD gpu architectures for the build target by using the checkbox function below.
# NAVI14 and VEGA support has not been tested with rocm 5.x or 6.x builds and are probaly not working.
#GPU_BUILD_AMD_NAVI14_GFX1012=1
#GPU_BUILD_AMD_VEGA_GFX902=1
# ---------------ROCM_SDK_BUILDER TARGET AMD GPU Selection Ends ------------

func_build_cfg_user() {
    ./build/checkbox.sh --message="Select ROCM SDK build target GPUs. Space to select, Enter to finish save, ESC to cancel." --options="gfx1010|gfx1030|gfx1035" --multiple
}

export ROCM_MAJOR_VERSION=6
export ROCM_MINOR_VERSION=0
export ROCM_PATCH_VERSION=0

SDK_ROOT_DIR="$PWD"

export INSTALL_DIR_PREFIX_SDK_ROOT=/opt/rocm_sdk_${ROCM_MAJOR_VERSION}${ROCM_MINOR_VERSION}${ROCM_PATCH_VERSION}
export ROCM_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}
export BUILD_RULE_ROOT_DIR=${SDK_ROOT_DIR}/binfo
export BUILD_SCRIPT_ROOT_DIR=${SDK_ROOT_DIR}/build
export ROCM_SDK_VERSION_INFO=rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
export UPSTREAM_REPO_VERSION_TAG_DEFAULT=rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
export PATCH_FILE_ROOT_DIR=${SDK_ROOT_DIR}/patches/${UPSTREAM_REPO_VERSION_TAG_DEFAULT}
export SDK_SRC_ROOT_DIR=${SDK_ROOT_DIR}/src_projects

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
# use by default total - 4 cpu's for building apps
if [ ! -v BUILD_CPU_COUNT_DEFAULT ]; then
    export BUILD_CPU_COUNT_DEFAULT=`nproc --ignore=4`
fi
if [ ! -v BUILD_CPU_COUNT ]; then
    export BUILD_CPU_COUNT=$BUILD_CPU_COUNT_DEFAULT
fi
# and for the apps consuming lot of resources we use half of the cpu's compared to regular
if [ ! -v BUILD_CPU_COUNT_HALF ]; then
    let BUILD_CPU_COUNT_HALF=$BUILD_CPU_COUNT_MAX/2
    export BUILD_CPU_COUNT_HALF
    #echo "BUILD_CPU_COUNT_HALF: $BUILD_CPU_COUNT_HALF"
fi

#export ROCM_VERSION_STR="${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}"
export ROCM_LIBPATCH_VERSION=${ROCM_MAJOR_VERSION}0${ROCM_MINOR_VERSION}0${ROCM_PATCH_VERSION}
export ROCM_VERSION_STR=${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
export ROCM_VERSION_STR_ZEROED_NO_DOTS=${ROCM_MAJOR_VERSION}0${ROCM_MINOR_VERSION}0${ROCM_PATCH_VERSION}
export CPACK_RPM_PACKAGE_RELEASE=01

export python=python

USER_CFG_FNAME='build_cfg.user'
unset USER_CONFIG_IS_OK
if [ -e ${USER_CFG_FNAME} ]; then
    while read CUR_GPU; do
        if [[ ${CUR_GPU} == gfx* ]] ; then
            USER_CONFIG_IS_OK=1
        else
            echo "Error, invalid option in build_cfg.user file."
            echo "Build options must start with word gfx"
        fi
    done < "${USER_CFG_FNAME}"
fi

if [ -z ${USER_CONFIG_IS_OK} ] || [ ! -e ${USER_CFG_FNAME} ] ; then
    func_build_cfg_user
fi

unset SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT
unset SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT
if [ -e ${USER_CFG_FNAME} ]; then
    while read CUR_GPU; do
        if [[ ${CUR_GPU} == gfx* ]] ; then
            if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
                SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT=${CUR_GPU}
                SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT=${CUR_GPU}
            else
                SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} ${CUR_GPU}"
                SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};${CUR_GPU}"
            fi
        fi
    done < "${USER_CFG_FNAME}"
fi

#unset SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT
#unset SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT
#if [[ ! -z ${GPU_BUILD_AMD_VEGA_GFX902} ]]; then
#    if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx902"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx902"
#    else
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} gfx902"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};gfx902"
#    fi
#fi
#if [[ ! -z ${GPU_BUILD_AMD_NAVI10_GFX1010} ]]; then
#    if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1010"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1010"
#    else
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} gfx1010"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};gfx1010"
#    fi
#fi
#if [[ ! -z ${GPU_BUILD_AMD_NAVI14_GFX1012} ]]; then
#    if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1012"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1012"
#    else
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} gfx1012"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};gfx1012"
#    fi
#fi
#if [[ ! -z ${GPU_BUILD_AMD_NAVI21_GFX1030} ]]; then
#    if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1030"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1030"
#    else
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} gfx1030"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};gfx1030"
#    fi
#fi
#if [[ ! -z ${GPU_BUILD_AMD_REMBRANDT_GFX1035} ]]; then
#    if [ ! -v SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT ]; then
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1035"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="gfx1035"
#    else
#        SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT} gfx1035"
#        SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT="${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT};gfx1035"
#    fi
#fi

#echo "rocm build targets: "
##echo ${SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT}
#echo ${SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT}
#sleep 2
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

export CMAKE_BUILD_TYPE_DEBUG=Debug
export CMAKE_BUILD_TYPE_RELEASE=Release
export CMAKE_BUILD_TYPE_RELWITHDEBINFO=RelWithDebInfo
#export CMAKE_BUILD_TYPE_DEFAULT=${CMAKE_BUILD_TYPE_RELWITHDEBINFO}
export CMAKE_BUILD_TYPE_DEFAULT=${CMAKE_BUILD_TYPE_RELEASE}
export APP_CMAKE_CFG_FLAGS_DEBUG="-DCMAKE_C_FLAGS_DEBUG=-g3 -DCMAKE_CXX_FLAGS_DEBUG=-g3"
export APP_CMAKE_CFG_FLAGS_DEFAULT="-DCMAKE_INSTALL_LIBDIR=lib64"
if [ ${CMAKE_BUILD_TYPE_DEFAULT} == ${CMAKE_BUILD_TYPE_DEBUG} ] || [ ${CMAKE_BUILD_TYPE_DEFAULT} == ${CMAKE_BUILD_TYPE_RELWITHDEBINFO} ]; then
    export APP_CMAKE_CFG_FLAGS_DEFAULT="${APP_CMAKE_CFG_FLAGS_DEFAULT} ${APP_CMAKE_CFG_FLAGS_DEBUG}"
    echo "APP_CMAKE_CFG_FLAGS_DEFAULT: ${APP_CMAKE_CFG_FLAGS_DEFAULT}"
fi
#export INSTALL_DIR_PREFIX_SDK_ROOT=$SDK_ROOT_DIR/install
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

#internal, choose one. SDK_CXX_COMPILER_NAME variable should not be used on any other scripts because
# these 3 names does not match with the names used by rocm for detecting the compiler.
# rocm is using only the following two names: "hcc" or "clang"
SDK_CXX_COMPILER_NAME="hipcc"
#SDK_CXX_COMPILER_NAME="hip_clang"

export SDK_PLATFORM_NAME_HIPCC="amd"
export SDK_PLATFORM_NAME_HIPCLANG="clang"

unset INSTALL_DIR_PREFIX_C_COMPILER

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

if [ -n ${INSTALL_DIR_PREFIX_C_COMPILER} ]; then
    export HIP_PATH_DEFAULT=${INSTALL_DIR_PREFIX_C_COMPILER}
else
    echo "no hip compiler defined"
    exit -1
fi

#HIP_PATH setup to /opt/rocm/hip breaks hipcc on rocm571
#export HIP_PATH=${HIP_PATH_DEFAULT}

export HIP_PLATFORM=${HIP_PLATFORM_DEFAULT}
export HIPCC_VERBOSE=7

export LD_LIBRARY_PATH=/lib64:${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64:${INSTALL_DIR_PREFIX_SDK_ROOT}/lib:${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib
export PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/bin:$PATH

if [ -e ${SDK_ROOT_DIR}/envsetup_post.cfg ]; then
    echo "Found and executing ${SDK_ROOT_DIR}/envsetup_post.cfg"
    source ${SDK_ROOT_DIR}/envsetup_post.cfg
fi

export HIP_PLATFORM=hcc
export ROCM_DIR=${INSTALL_DIR_PREFIX_SDK_ROOT}
export HCC_HOME=${INSTALL_DIR_PREFIX_SDK_ROOT}/hcc
export HCC_PATH=${HCC_HOME}/bin
export HIP_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}
export ROCBLAS_HOME=${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas

export LD_LIBRARY_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${ROCBLAS_HOME}/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${HCC_HOME}/lib:${LD_LIBRARY_PATH}

export PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/hcc/bin:${PATH}
export PATH=${INSTALL_DIR_PREFIX_SDK_ROOT}/bin:${PATH}

export LDFLAGS="-L${INSTALL_DIR_PREFIX_SDK_ROOT}/lib64 -L${INSTALL_DIR_PREFIX_SDK_ROOT}/lib -L${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/lib -L${ROCBLAS_HOME}/lib -L${HCC_HOME}/lib"
export CFLAGS="-I${INSTALL_DIR_PREFIX_SDK_ROOT}/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocm_smi/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas/include"
export CPPFLAGS="-I${INSTALL_DIR_PREFIX_SDK_ROOT}/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/hsa/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocm_smi/include -I${INSTALL_DIR_PREFIX_SDK_ROOT}/rocblas/include"
export PKG_CONFIG_PATH="{INSTALL_DIR_PREFIX_SDK_ROOT}/lib64/pkgconfig:{INSTALL_DIR_PREFIX_SDK_ROOT}/lib/pkgconfig:{INSTALL_DIR_PREFIX_SDK_ROOT}/share/pkgconfig"

func_binfo_utils__init_binfo_app_list

