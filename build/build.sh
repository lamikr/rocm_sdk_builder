#!/bin/bash

#
# Copyright (c) 2024 by Mika Laitio <lamikr@gmail.com>
#
# License: GNU Lesser General Public License (LGPL), version 2.1 or later.
# See the lgpl.txt file in the root directory or <http://www.gnu.org/licenses/lgpl-2.1.html>.
#

if [ -z ${SDK_ROOT_DIR} ]; then
    echo "initializing build environment variables"
    source ./binfo/envsetup.sh
    #source /opt/rocm_sdk_571/bin/env_rocm_tensorflow_hip_hcc.sh
fi

func_build_init() {
    export CCACHE_DIR="${HOME}/.ccache"
    export CCACHE_TEMPDIR="${HOME}/.ccache"
    ccache -M 30G
    echo "SDK_ROOT_DIR: ${SDK_ROOT_DIR}"
}

func_build_all() {
    ii=0
    APP_CFLAGS_DEFAULT=${CFLAGS}
    APP_CPPFLAGS_DEFAULT=${CPPFLAGS}
    APP_LDFLAGS_DEFAULT=${LDFLAGS}
    APP_LD_LIBRARY_PATH_DEFAULT=${LD_LIBRARY_PATH}
    APP_PATH_DEFAULT=${PATH}
    APP_PKG_CONFIG_PATH_DEFAULT=${PKG_CONFIG_PATH}
    while [ "x${LIST_BINFO_FILE_FULLNAME[ii]}" != "x" ]
    do
        echo "LIST_BINFO_FILE_FULLNAME[${ii}]: ${LIST_BINFO_FILE_FULLNAME[${ii}]}"
        #set build and install array commands that can be used for overriding default behavior to empty
        unset BINFO_APP_CMAKE_CFG
        unset BINFO_APP_PRE_CONFIG_CMD_ARRAY
        unset BINFO_APP_CONFIG_CMD_ARRAY
        unset BINFO_APP_POST_CONFIG_CMD_ARRAY
        unset BINFO_APP_BUILD_CMD_ARRAY
        unset BINFO_APP_INSTALL_CMD_ARRAY
        unset BINFO_APP_POST_INSTALL_CMD_ARRAY
        unset BINFO_APP_CMAKE_BUILD_TYPE

        unset BINFO_APP_NO_PRECONFIG
        unset BINFO_APP_NO_CONFIG
        unset BINFO_APP_NO_POSTCONFIG
        unset BINFO_APP_NO_BUILD
        unset BINFO_APP_NO_INSTALL
        unset BINFO_APP_NO_POSTINSTALL
        unset BINFO_APP_NO_BUILD_CMD_RESULT_CHECK
        unset BINFO_APP_NO_INSTALL_CMD_RESULT_CHECK
        unset BINFO_APP_PRE_CONFIG_CMD_EXECUTE_ALWAYS
        unset BINFO_APP_CONFIG_CMD_EXECUTE_ALWAYS
        unset BINFO_APP_POST_CONFIG_CMD_EXECUTE_ALWAYS
        unset BINFO_APP_POST_INSTALL_CMD_EXECUTE_ALWAYS

        unset BINFO_APP_PRECONFIG_LDFLAGS

        export CFLAGS=${APP_CFLAGS_DEFAULT}
        export CPPFLAGS_DEFAULT=${APP_CPPFLAGS_DEFAULT}
        export LDFLAGS=${APP_LDFLAGS_DEFAULT}
        export LD_LIBRARY_PATH=${APP_LD_LIBRARY_PATH_DEFAULT}
        export PATH=${APP_PATH_DEFAULT}
        export PKG_CONFIG_PATH=${APP_PKG_CONFIG_PATH_DEFAULT}

        #reset value if previus module script overwrote this
        #HIP_PATH setup to /opt/rocm/hip breaks hipcc on rocm571
        #export HIP_PATH=${HIP_PATH_DEFAULT}
        export HIP_PLATFORM=${HIP_PLATFORM_DEFAULT}

        APP_INFO_BASE_NAME=${LIST_BINFO_FILE_FULLNAME[${ii}]}
        APP_INFO_BASE_NAME=$(basename ${APP_INFO_BASE_NAME} .binfo)
        BINFO_APP_BUILD_DIR="${BUILD_ROOT_DIR}/${APP_INFO_BASE_NAME}"

        #read config and build commands
        source ${LIST_BINFO_FILE_FULLNAME[${ii}]}
        res=$?
        if [ ! $res -eq 0 ]; then
            echo "failed to execute build env script: ${LIST_BINFO_FILE_FULLNAME[${ii}]}"
            exit 1
        fi

        TASK_RESULT_FILE_PRECONFIG=${BINFO_APP_BUILD_DIR}/.result_preconfig
        TASK_RESULT_FILE_CFG=${BINFO_APP_BUILD_DIR}/.result_config
        TASK_RESULT_FILE_POSTCONFIG=${BINFO_APP_BUILD_DIR}/.result_postconfig
        TASK_RESULT_FILE_BUILD=${BINFO_APP_BUILD_DIR}/.result_build
        TASK_RESULT_FILE_INSTALL=${BINFO_APP_BUILD_DIR}/.result_install
        TASK_RESULT_FILE_POSTINSTALL=${BINFO_APP_BUILD_DIR}/.result_postinstall

        echo ""
        echo "---------------------------"
        echo "BINFO_APP_NAME: ${BINFO_APP_NAME}"
        echo "BINFO FILE: ${LIST_BINFO_FILE_FULLNAME[ii]}"
        echo "BINFO_APP_SRC_SUBDIR_BASENAME: ${BINFO_APP_SRC_SUBDIR_BASENAME}"
        echo "BINFO_APP_SRC_TOPDIR_BASENAME: ${BINFO_APP_SRC_TOPDIR_BASENAME}"
        echo "BINFO_APP_SRC_DIR: ${BINFO_APP_SRC_DIR}"
        echo "BINFO_APP_BUILD_DIR: ${BINFO_APP_BUILD_DIR}"
        echo "HIP_PATH: ${HIP_PATH}"
        echo "INSTALL_DIR: ${INSTALL_DIR_PREFIX_SDK_ROOT}"
        echo "HIP_PLATFORM: ${HIP_PLATFORM}"

        echo "TASK_RESULT_FILE_INSTALL: ${TASK_RESULT_FILE_INSTALL}"
        echo "---------------------------"
        echo ""

        if [ ! -d ${BINFO_APP_SRC_DIR} ]; then
            echo "Build failed, application source dir does not exist: ${BINFO_APP_SRC_DIR}"
            exit 1
        fi

        res=0
        if [ $res -eq 0 ]; then
            if [ ! -z ${BINFO_APP_PRE_CONFIG_CMD_EXECUTE_ALWAYS} ] || [ ! -f ${TASK_RESULT_FILE_PRECONFIG} ]; then
                mkdir -p ${BINFO_APP_BUILD_DIR}
                cd ${BINFO_APP_BUILD_DIR}
                echo ""
                pwd
                res=0
                if [ ! -v BINFO_APP_NO_PRECONFIG ]; then
                    echo "pre-configuring ${BINFO_APP_NAME}"
                    if [ -z "${BINFO_APP_PRE_CONFIG_CMD_ARRAY}" ]; then
                        echo "no pre-configuration commands"
                    else
                        echo "pre-configuration"
                        jj=0
                        while [ "x${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]}" != "x" ]
                        do
                            echo "${BINFO_APP_NAME}, pre-configuration command ${jj}"
                            #echo "${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]}"
                            eval ${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]} || exit
                            res=$?
                            if [ ${res} -eq 0 ]; then
                                jj=$(( ${jj} + 1 ))
                                echo "pre-configuration cmd ok: ${BINFO_APP_NAME}"
                            else
                                echo "pre-configuration failed: ${BINFO_APP_NAME}"
                                echo "  error in pre-configuration cmd: ${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]}"
                                exit 1
                            fi
                            #sleep 1
                        done
                    fi
                fi
                if [ ${res} -eq 0 ]; then
                    echo "pre-configuration ok: ${BINFO_APP_NAME}"
                    echo ${res} > ${TASK_RESULT_FILE_PRECONFIG}
                else
                    echo "pre-configuration failed: ${BINFO_APP_NAME}"
                    exit 1
                fi
            fi
        fi
        if [ $res -eq 0 ]; then
            if [ ! -z ${BINFO_APP_CONFIG_CMD_EXECUTE_ALWAYS} ] || [ ! -f ${TASK_RESULT_FILE_CFG} ]; then
                cd ${BINFO_APP_BUILD_DIR}
                echo ""
                env
                echo ""
                pwd
                res=0
                if [ ! -v BINFO_APP_NO_CONFIG ]; then
                    echo "configuring: ${BINFO_APP_NAME}"
                    if [ -z "${BINFO_APP_CONFIG_CMD_ARRAY}" ]; then
                        if [[ -z ${BINFO_APP_CMAKE_CFG} || ${BINFO_APP_CMAKE_CFG} = ’’ ]]; then
                            echo "BINFO_APP_CMAKE_CFG not set"
                        else
                            echo "BINFO_APP_CMAKE_CFG: ${BINFO_APP_CMAKE_CFG}"
                            BINFO_APP_CMAKE_CFG="${APP_CMAKE_CFG_FLAGS_DEFAULT} ${BINFO_APP_CMAKE_CFG}"
                            if [[ -z ${BINFO_APP_CMAKE_BUILD_TYPE} || ${BINFO_APP_CMAKE_BUILD_TYPE} = ’’ ]]; then
                                BINFO_APP_CMAKE_CFG="-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE_DEFAULT} ${BINFO_APP_CMAKE_CFG}"
                                echo "BINFO_APP_CMAKE_CFG: ${BINFO_APP_CMAKE_CFG}"
                            else
                                BINFO_APP_CMAKE_CFG="-DCMAKE_BUILD_TYPE=${BINFO_APP_CMAKE_BUILD_TYPE} ${BINFO_APP_CMAKE_CFG}"
                                echo "BINFO_APP_CMAKE_CFG: ${BINFO_APP_CMAKE_CFG}"
                            fi
                            echo "Configuring ${BINFO_APP_NAME}"
                            #echo "CXX: ${CXX}"
                            echo cmake ${BINFO_APP_CMAKE_CFG}
                            cmake ${BINFO_APP_CMAKE_CFG}
                            res=$?
                        fi
                    else
                        res=0
                        jj=0
                        while [ "x${BINFO_APP_CONFIG_CMD_ARRAY[jj]}" != "x" ]
                        do
                            echo "${BINFO_APP_NAME}, config command ${jj}"
                            echo "${BINFO_APP_CONFIG_CMD_ARRAY[jj]}"
                            eval ${BINFO_APP_CONFIG_CMD_ARRAY[jj]} || exit
                            res=$?
                            if [ ${res} -eq 0 ]; then
                                jj=$(( ${jj} + 1 ))
                            else
                                echo "Configuration failed: ${BINFO_APP_NAME}"
                                echo "  error in config cmd: ${BINFO_APP_CONFIG_CMD_ARRAY[jj]}"
                                exit 1
                            fi
                        done
                    fi
                else
                    echo "no config"
                fi
                if [ $res -eq 0 ]; then
                    echo "configure ok: ${BINFO_APP_NAME}"
                    echo ${res} > ${TASK_RESULT_FILE_CFG}
                    sync
                    sleep 2
                else
                    echo "configure failed: ${BINFO_APP_NAME}"
                    exit 1
                fi
            fi
        fi
        if [ $res -eq 0 ]; then
            #echo "BINFO_APP_POST_CONFIG_CMD_EXECUTE_ALWAYS: ${BINFO_APP_POST_CONFIG_CMD_EXECUTE_ALWAYS}"
            if [ ! -z ${BINFO_APP_POST_CONFIG_CMD_EXECUTE_ALWAYS} ] || [ ! -f ${TASK_RESULT_FILE_POSTCONFIG} ]; then
                mkdir -p ${BINFO_APP_BUILD_DIR}
                cd ${BINFO_APP_BUILD_DIR}
                echo ""
                pwd
                res=0
                if [ ! -v BINFO_APP_NO_POSTCONFIG ]; then
                    echo "post-configuration ${BINFO_APP_NAME}"
                    if [ -z "${BINFO_APP_POST_CONFIG_CMD_ARRAY}" ]; then
                        echo "no post-configuration commands"
                    else
                        echo "post-configuration"
                        jj=0
                        while [ "x${BINFO_APP_POST_CONFIG_CMD_ARRAY[jj]}" != "x" ]
                        do
                            echo "${BINFO_APP_NAME}, post-configuration command ${jj}"
                            echo "${BINFO_APP_POST_CONFIG_CMD_ARRAY[jj]}"
                            eval ${BINFO_APP_POST_CONFIG_CMD_ARRAY[jj]} || exit
                            res=$?
                            if [ ${res} -eq 0 ]; then
                                jj=$(( ${jj} + 1 ))
                                echo "post-configuration cmd ok ${BINFO_APP_NAME}"
                            else
                                echo "post-configuration failed: ${BINFO_APP_NAME}"
                                echo "  error in post-configuration cmd: ${BINFO_APP_POST_CONFIG_CMD_ARRAY[jj]}"
                                exit 1
                            fi
                            #sleep 1
                        done
                    fi
                fi
                if [ ${res} -eq 0 ]; then
                    echo "post-configuration ok: ${BINFO_APP_NAME}"
                    echo ${res} > ${TASK_RESULT_FILE_POSTCONFIG}
                else
                    echo "post-configuration failed: ${BINFO_APP_NAME}"
                    exit 1
                fi
            fi
        fi
        if [ $res -eq 0 ]; then
            if [ ! -f ${TASK_RESULT_FILE_BUILD} ]; then
                cd ${BINFO_APP_BUILD_DIR}
                echo ""
                pwd
                res=0
                if [ ! -v BINFO_APP_NO_BUILD ]; then
                    echo "Building ${BINFO_APP_NAME}"
                    if [ -z "${BINFO_APP_BUILD_CMD_ARRAY}" ]; then
                        echo "make -j${BINFO_BUILD_CPU_COUNT}"
                        make VERBOSE=1 -j${BINFO_BUILD_CPU_COUNT}
                        res=$?
                    else
                        res=0
                        jj=0
                        while [ "x${BINFO_APP_BUILD_CMD_ARRAY[jj]}" != "x" ]
                        do
                            exec_cmd=${BINFO_APP_BUILD_CMD_ARRAY[jj]}
                            echo "[${jj}] ${BINFO_APP_NAME}, build command:"
                            echo "${exec_cmd}"
                            ${exec_cmd}
                            res=$?
                            if [ -v BINFO_APP_NO_BUILD_CMD_RESULT_CHECK ]; then
                                echo "build cmd result check skip, res was: ${res}, ${BINFO_APP_NO_BUILD_CMD_RESULT_CHECK}"
                                sleep 1
                                res=0
                            fi
                            if [ ${res} -eq 0 ]; then
                                jj=$(( ${jj} + 1 ))
                            else
                                echo "build failed: ${BINFO_APP_NAME}"
                                echo "  error in build cmd: ${BINFO_APP_BUILD_CMD_ARRAY[jj]}"
                                exit 1
                            fi
                        done
                    fi
                fi
                if [ ${res} -eq 0 ]; then
                    echo "build ok: ${BINFO_APP_NAME}"
                    echo ${res} > ${TASK_RESULT_FILE_BUILD}
                    sync
                    sleep 2
                else
                    echo "build failed: ${BINFO_APP_NAME}"
                    exit 1
                fi
            fi
        fi
        if [ $res -eq 0 ]; then
            if [ ! -f ${TASK_RESULT_FILE_INSTALL} ]; then
                cd ${BINFO_APP_BUILD_DIR}
                echo ""
                pwd
                res=0
                if [ ! -v BINFO_APP_NO_INSTALL ]; then
                    echo "installing ${BINFO_APP_NAME}"
                    if [ -z ${BINFO_APP_INSTALL_CMD_ARRAY} ]; then
                        echo "make install"
                        make install
                        res=$?
                    else
                        echo "custom install"
                        jj=0
                        while [ "x${BINFO_APP_INSTALL_CMD_ARRAY[jj]}" != "x" ]
                        do
                            echo "${BINFO_APP_NAME}, install command ${jj}"
                            echo "${BINFO_APP_INSTALL_CMD_ARRAY[jj]}"
                            eval ${BINFO_APP_INSTALL_CMD_ARRAY[jj]} || exit
                            res=$?
                            if [ -v BINFO_APP_NO_INSTALL_CMD_RESULT_CHECK ]; then
                                res=0
                            fi
                            if [ ${res} -eq 0 ]; then
                                jj=$(( ${jj} + 1 ))
                                echo "install cmd ok: ${BINFO_APP_NAME}"
                            else
                                echo "install failed: ${BINFO_APP_NAME}"
                                echo "  error in install cmd: ${BINFO_APP_INSTALL_CMD_ARRAY[jj]}"
                                exit 1
                            fi
                            sleep 1
                        done
                    fi
                fi
                if [ ${res} -eq 0 ]; then
                    echo "install ok: ${BINFO_APP_NAME}"
                    echo ${res} > ${TASK_RESULT_FILE_INSTALL}
                    sync
                    sleep 2
                else
                    echo "install failed: ${BINFO_APP_NAME}"
                    exit 1
                fi
            fi
        fi
        if [ $res -eq 0 ]; then
            if [ ! -z ${BINFO_APP_POST_INSTALL_CMD_EXECUTE_ALWAYS} ] || [ ! -f ${TASK_RESULT_FILE_POSTINSTALL} ]; then
                cd ${BINFO_APP_BUILD_DIR}
                echo ""
                pwd
                res=0
                if [ ! -v BINFO_APP_NO_POSTINSTALL ]; then
                    echo "post installing ${BINFO_APP_NAME}"
                    if [ -z "${BINFO_APP_POST_INSTALL_CMD_ARRAY}" ]; then
                        echo "no post install commands"
                    else
                        echo "post install"
                        jj=0
                        while [ "x${BINFO_APP_POST_INSTALL_CMD_ARRAY[jj]}" != "x" ]
                        do
                            echo "${BINFO_APP_NAME}, post install command ${jj}"
                            echo "${BINFO_APP_POST_INSTALL_CMD_ARRAY[jj]}"
                            eval ${BINFO_APP_POST_INSTALL_CMD_ARRAY[jj]} || exit
                            res=$?
                            if [ ${res} -eq 0 ]; then
                                jj=$(( ${jj} + 1 ))
                                echo "post-install cmd ok: ${BINFO_APP_NAME}"
                            else
                                echo "post-install failed: ${BINFO_APP_NAME}"
                                echo "  error in post-install cmd: ${BINFO_APP_POST_INSTALL_CMD_ARRAY[jj]}"
                                exit 1
                            fi
                            #sleep 1
                        done
                    fi
                fi
                if [ ${res} -eq 0 ]; then
                    echo "post install ok: ${BINFO_APP_NAME}"
                    echo ${res} > ${TASK_RESULT_FILE_POSTINSTALL}
                else
                    echo "post install failed: ${BINFO_APP_NAME}"
                    exit 1
                fi
            fi
        fi
        ii=$(( ${ii} + 1 ))
    done
}

func_build_init
func_build_all
