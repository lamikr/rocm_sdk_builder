#!/bin/bash

#
# Copyright (c) 2024 by Mika Laitio <lamikr@gmail.com>
#
# License: GNU Lesser General Public License (LGPL), version 2.1 or later.
# See the lgpl.txt file in the root directory or <http://www.gnu.org/licenses/lgpl-2.1.html>.
#
source build/git_utils.sh

func_upstream_remote_repo_add() {
    local CUR_APP_UPSTREAM_REPO_DEFINED=0
    local CUR_APP_UPSTREAM_REPO_ADDED=0
    local ii

    if [[ -n "$1" ]]; then
        ii=$1
    else
        ii=1
    fi

    if [[ -n "${BINFO_APP_UPSTREAM_REPO_URL-}" ]]; then
        CUR_APP_UPSTREAM_REPO_DEFINED=1
    fi
    # Initialize git repositories and add upstream remote
    if [ "x${BINFO_APP_SRC_CLONE_DIR}" != "x" ]; then
        if [ ! -d ${BINFO_APP_SRC_CLONE_DIR} ]; then
            echo ""
            echo "[${ii}] Creating repository source code directory: ${BINFO_APP_SRC_CLONE_DIR}"
            sleep 0.1
            mkdir -p ${BINFO_APP_SRC_CLONE_DIR}
            # LIST_APP_ADDED_UPSTREAM_REPO parameter is used in
            # situations where same src_code directory is used for building multiple projects
            # with just different configure parameters (for example amd-fftw)
            # in this case we want to add upstream repo and apply patches only once
            CUR_APP_UPSTREAM_REPO_ADDED=1
        fi
        if [ "$CUR_APP_UPSTREAM_REPO_DEFINED" == "1" ]; then
            if [ ! -d ${BINFO_APP_SRC_CLONE_DIR}/.git ]; then
                cd "${BINFO_APP_SRC_CLONE_DIR}"
                echo ""
                echo "[${ii}] Repository Init"
                echo "Repository name: ${BINFO_APP_NAME}"
                echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                echo "Source directory: ${BINFO_APP_SRC_CLONE_DIR}"
                echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                sleep 0.5
                git init
                echo ${BINFO_APP_UPSTREAM_REPO_URL}
                git remote add upstream ${BINFO_APP_UPSTREAM_REPO_URL}
                CUR_APP_UPSTREAM_REPO_ADDED=1
            else
                CUR_APP_UPSTREAM_REPO_ADDED=0
                echo "${BINFO_APP_SRC_CLONE_DIR} ok"
            fi
        else
            CUR_APP_UPSTREAM_REPO_ADDED=0
            echo "${BINFO_APP_SRC_CLONE_DIR} submodule ok"
        fi
        sleep 0.1

        # Fetch updates and initialize submodules
        #echo "CUR_APP_UPSTREAM_REPO_ADDED: ${CUR_APP_UPSTREAM_REPO_ADDED}"
        # check if directory was just created and git fetch needs to be done
        if [ ${CUR_APP_UPSTREAM_REPO_ADDED} -eq 1 ]; then
            echo ""
            echo "[${ii}] Repository Source Code Fetch"
            echo "Repository name: ${BINFO_APP_NAME}"
            echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
            echo "Source directory: ${BINFO_APP_SRC_CLONE_DIR}"
            echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
            cd "${BINFO_APP_SRC_CLONE_DIR}"
            git fetch upstream
            if [ $? -ne 0 ]; then
                echo "git fetch failed: ${BINFO_APP_SRC_CLONE_DIR}"
                #exit 1
            fi
            git fetch upstream --force --tags
            git checkout "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
            func_is_current_dir_a_git_submodule_dir #From build/git_utils.sh
            cur_res=$?
            if [ ${cur_res} == "1" ]; then
                echo ""
                echo "[${ii}] Submodule Init"
                echo "Repository name: ${BINFO_APP_NAME}"
                echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                echo "Source directory: ${BINFO_APP_SRC_CLONE_DIR}"
                echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                git submodule update --init --recursive
                if [ $? -ne 0 ]; then
                    echo "git submodule init and update failed: ${BINFO_APP_SRC_CLONE_DIR}"
                    exit 1
                fi
            fi
        fi

        local CUR_APP_PATCH_DIR="${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}"
        # Apply patches if patch directory exist
        # check if directory was just created and git am needs to be done
        if [ ${CUR_APP_UPSTREAM_REPO_ADDED} -eq 1 ]; then
            local TEMP_PATCH_DIR=${CUR_APP_PATCH_DIR}
            cd "${BINFO_APP_SRC_CLONE_DIR}"
            if [ -d "${TEMP_PATCH_DIR}" ]; then
                if [ ! -z "$(ls -A $TEMP_PATCH_DIR)" ]; then
                    echo ""
                    echo "[${ii}] Applying Patches"
                    echo "Repository name: ${BINFO_APP_NAME}"
                    echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                    echo "Source directory: ${BINFO_APP_SRC_CLONE_DIR}"
                    echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                    echo "Patch dir: ${TEMP_PATCH_DIR}"
                    git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
                    if [ $? -ne 0 ]; then
                        git am --abort
                        echo ""
                        echo "Error, failed to Apply Patches"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${BINFO_APP_SRC_CLONE_DIR}"
                        echo "Version tag: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        echo "Patch dir: ${TEMP_PATCH_DIR}"
                        echo ""
                        exit 1
                    else
                        echo "Patches Applied: ${BINFO_APP_SRC_CLONE_DIR}"
                    fi
                else
                   echo "Warning, patch directory exist but is empty: ${TEMP_PATCH_DIR}"
                   sleep 2
                fi
            else
                true
                #echo "patch directory does not exist: ${TEMP_PATCH_DIR}"
                #sleep 2
            fi
        fi
    fi
    echo ""
    echo "All new source code repositories added and initialized ok"
}

func_upstream_remote_repo_add_by_binfo() {
    local ii

    APP_INFO_FULL_NAME=$1
    if [[ -n "$2" ]]; then
        ii=$2
    else
        ii=1
    fi

    echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"
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
    unset BINFO_APP_UPSTREAM_REPO_VERSION_TAG

    #read config and build commands
    source ${APP_INFO_FULL_NAME}
    res=$?
    if [ ! $res -eq 0 ]; then
        echo "failed to execute build env script: ${APP_INFO_FULL_NAME}"
        exit 1
    fi

    # Initialize BINFO_APP_SRC_CLONE_DIR variable if it is not specified in the binfo file
    if [[ ! -n "${BINFO_APP_SRC_CLONE_DIR}" ]]; then
        if [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
            BINFO_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_DIR}"
        else
            echo "Error, you must define either the BINFO_APP_SRC_DIR or BINFO_APP_SRC_CLONE_DIR in ${APP_INFO_FULL_NAME}"
            exit 1
        fi
    fi

    # Initialize upstream repository version tag
    if [[ -n "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG-}" ]]; then
        BINFO_APP_UPSTREAM_REPO_VERSION_TAG="${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
    else
        BINFO_APP_UPSTREAM_REPO_VERSION_TAG="${UPSTREAM_REPO_VERSION_TAG_DEFAULT}"
    fi
    if [ ! -d ${BINFO_APP_SRC_CLONE_DIR} ]; then
        func_upstream_remote_repo_add ${ii}
    fi
}

func_upstream_remote_repo_add_by_blist() {
    local ii
    local BINFO_ARRAY

    ii=0
    readarray -t BINFO_ARRAY < $1
    if [[ ${BINFO_ARRAY[@]} ]]; then
        local FNAME
        for FNAME in "${BINFO_ARRAY[@]}"; do
            if [ ! -z ${FNAME} ]; then
               if  [ -z ${FNAME##*.binfo} ]; then
                   ii=$(( ${ii} + 1 ))
                   cd ${SDK_ROOT_DIR}
                   func_upstream_remote_repo_add_by_binfo ${FNAME} ${ii}
               fi
            fi
        done
    else
        echo ""
        echo "Failed to add repositories by using the blist file."
        echo "Could not find binfo files listed in:"
        echo "    $1"
        echo ""
        exit 1
    fi
}

func_build_env_init() {
    if [ -z ${SDK_ROOT_DIR} ]; then
        echo "initializing build environment variables"
        source ./binfo/envsetup.sh
        #source /opt/rocm_sdk_571/bin/env_rocm_tensorflow_hip_hcc.sh
    fi
    export CCACHE_DIR="${HOME}/.ccache"
    export CCACHE_TEMPDIR="${HOME}/.ccache"
    ccache -M 30G
    echo "SDK_ROOT_DIR: ${SDK_ROOT_DIR}"
    
    APP_CFLAGS_DEFAULT=${CFLAGS}
    APP_CPPFLAGS_DEFAULT=${CPPFLAGS}
    APP_LDFLAGS_DEFAULT=${LDFLAGS}
    APP_LD_LIBRARY_PATH_DEFAULT=${LD_LIBRARY_PATH}
    APP_PATH_DEFAULT=${PATH}
    APP_PKG_CONFIG_PATH_DEFAULT=${PKG_CONFIG_PATH}
}

func_build_env_deinit() {
	CFLAGS=${APP_CFLAGS_DEFAULT}
    CPPFLAGS=${APP_CPPFLAGS_DEFAULT}
    LDFLAGS=${APP_LDFLAGS_DEFAULT}
    LD_LIBRARY_PATH=${APP_LD_LIBRARY_PATH_DEFAULT}
    PATH=${APP_PATH_DEFAULT}
    PKG_CONFIG_PATH=${APP_PKG_CONFIG_PATH_DEFAULT}
}

func_build_single_binfo() {
	local ii;
	APP_INFO_FULL_NAME=$1

    if [[ -n "$2" ]]; then
        ii=$2
    else
        ii=1
    fi

    echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"
	#set build and install array commands that can be used for overriding default behavior to empty
	unset BINFO_APP_CMAKE_CFG
	unset BINFO_APP_SRC_DIR
	unset BINFO_APP_SRC_CLONE_DIR
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

	APP_INFO_BASE_NAME=$( basename ${APP_INFO_FULL_NAME} .binfo)
	BINFO_APP_BUILD_DIR="${BUILD_ROOT_DIR}/${APP_INFO_BASE_NAME}"
	
	unset BINFO_APP_UPSTREAM_REPO_VERSION_TAG
	
	#read config and build commands
	source ${APP_INFO_FULL_NAME}
	res=$?
	if [ ! $res -eq 0 ]; then
		echo "failed to execute build env script: ${APP_INFO_FULL_NAME}"
		exit 1
	fi

    # Initialize BINFO_APP_SRC_CLONE_DIR variable if it is not specified in the binfo file
    if [[ ! -n "${BINFO_APP_SRC_CLONE_DIR}" ]]; then
        if [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
            BINFO_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_DIR}"
        else
            echo "Error, you must define either the BINFO_APP_SRC_DIR or BINFO_APP_SRC_CLONE_DIR in ${APP_INFO_FULL_NAME}"
            exit 1
        fi
    fi

    # Initialize upstream repository version tag
    if [[ -n "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG-}" ]]; then
        BINFO_APP_UPSTREAM_REPO_VERSION_TAG="${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
    else
        BINFO_APP_UPSTREAM_REPO_VERSION_TAG="${UPSTREAM_REPO_VERSION_TAG_DEFAULT}"
    fi

	TASK_RESULT_FILE_PRECONFIG=${BINFO_APP_BUILD_DIR}/.result_preconfig
	TASK_RESULT_FILE_CFG=${BINFO_APP_BUILD_DIR}/.result_config
	TASK_RESULT_FILE_POSTCONFIG=${BINFO_APP_BUILD_DIR}/.result_postconfig
	TASK_RESULT_FILE_BUILD=${BINFO_APP_BUILD_DIR}/.result_build
	TASK_RESULT_FILE_INSTALL=${BINFO_APP_BUILD_DIR}/.result_install
	TASK_RESULT_FILE_POSTINSTALL=${BINFO_APP_BUILD_DIR}/.result_postinstall

	echo ""
	echo "---------------------------"
	echo "[${ii}] BINFO_APP_NAME: ${BINFO_APP_NAME}"
	echo "BINFO FILE: ${APP_INFO_FULL_NAME}"
	echo "BINFO_APP_SRC_SUBDIR_BASENAME: ${BINFO_APP_SRC_SUBDIR_BASENAME}"
	echo "BINFO_APP_SRC_TOPDIR_BASENAME: ${BINFO_APP_SRC_TOPDIR_BASENAME}"
	echo "BINFO_APP_SRC_DIR: ${BINFO_APP_SRC_DIR}"
	echo "BINFO_APP_SRC_CLONE_DIR: ${BINFO_APP_SRC_CLONE_DIR}"
	echo "BINFO_APP_BUILD_DIR: ${BINFO_APP_BUILD_DIR}"
	echo "HIP_PATH: ${HIP_PATH}"
	echo "INSTALL_DIR: ${INSTALL_DIR_PREFIX_SDK_ROOT}"
	echo "HIP_PLATFORM: ${HIP_PLATFORM}"

	echo "TASK_RESULT_FILE_INSTALL: ${TASK_RESULT_FILE_INSTALL}"
	echo "---------------------------"
	echo ""

	if [ ! -d ${BINFO_APP_SRC_CLONE_DIR} ]; then
		func_upstream_remote_repo_add ${ii}
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
				echo "[${ii}] Pre-configuration: ${BINFO_APP_NAME}"
				if [ -z "${BINFO_APP_PRE_CONFIG_CMD_ARRAY}" ]; then
					echo "no pre-configuration commands"
				else
					echo "[Pre-configuration"
					jj=0
					while [ "x${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]}" != "x" ]
					do
						echo "${BINFO_APP_NAME}, pre-configuration command ${jj}"
						#echo "${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]}"
						eval ${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]} || exit
						res=$?
						if [ ${res} -eq 0 ]; then
							jj=$(( ${jj} + 1 ))
							echo "Pre-configuration cmd ok: ${BINFO_APP_NAME}"
						else
							echo "Pre-configuration failed: ${BINFO_APP_NAME}"
							echo "  error in pre-configuration cmd: ${BINFO_APP_PRE_CONFIG_CMD_ARRAY[jj]}"
							exit 1
						fi
						#sleep 1
					done
				fi
			fi
			if [ ${res} -eq 0 ]; then
				echo "Pre-configuration ok: ${BINFO_APP_NAME}"
				echo ${res} > ${TASK_RESULT_FILE_PRECONFIG}
			else
				echo "Pre-configuration failed: ${BINFO_APP_NAME}"
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
			    pwd
				echo "[${ii}] Configuration: ${BINFO_APP_NAME}"
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
				echo "[${ii}] Post-configuration: ${BINFO_APP_NAME}"
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
	    if [ ! -z ${BINFO_APP_BUILD_CMD_EXECUTE_ALWAYS} ] || [ ! -f ${TASK_RESULT_FILE_BUILD} ]; then
			cd ${BINFO_APP_BUILD_DIR}
			echo ""
			pwd
			res=0
			if [ ! -v BINFO_APP_NO_BUILD ]; then
				echo "[${ii}] Building: ${BINFO_APP_NAME}"
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
	    if [ ! -z ${BINFO_APP_INSTALL_CMD_EXECUTE_ALWAYS} ] || [ ! -f ${TASK_RESULT_FILE_INSTALL} ]; then
			cd ${BINFO_APP_BUILD_DIR}
			echo ""
			pwd
			res=0
			if [ ! -v BINFO_APP_NO_INSTALL ]; then
				echo "[${ii}] Installing: ${BINFO_APP_NAME}"
				if [ -z "${BINFO_APP_INSTALL_CMD_ARRAY}" ]; then
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
				echo "[${ii}] Post-installing: ${BINFO_APP_NAME}"
				if [ -z "${BINFO_APP_POST_INSTALL_CMD_ARRAY}" ]; then
					echo "no post-install commands"
				else
					echo "post-install"
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
				echo "post-install ok: ${BINFO_APP_NAME}"
				echo ${res} > ${TASK_RESULT_FILE_POSTINSTALL}
            else
                echo "post-install failed: ${BINFO_APP_NAME}"
                exit 1
            fi
        fi
    fi
}

func_init_and_build_single_binfo() {
    func_build_env_init
    # force to run build and install steps always when doing single app build
    BINFO_APP_BUILD_CMD_EXECUTE_ALWAYS=1
    BINFO_APP_INSTALL_CMD_EXECUTE_ALWAYS=1
    func_build_single_binfo $1 1
    func_build_env_deinit
    return 0
}

func_init_and_build_blist() {
    local ii
    local BINFO_ARRAY

    ii=0
    readarray -t BINFO_ARRAY < $1
    if [[ ${BINFO_ARRAY[@]} ]]; then
        func_build_env_init

        local FNAME
        for FNAME in "${BINFO_ARRAY[@]}"; do
            if [ ! -z ${FNAME} ]; then
               if  [ -z ${FNAME##*.binfo} ]; then
                   ii=$(( ${ii} + 1 ))
                   cd ${SDK_ROOT_DIR}
                   func_build_single_binfo ${FNAME} ${ii}
               fi
            fi
        done
    else
        echo ""
        echo "Failed to build by using the blist file."
        echo "Could not find binfo files listed in:"
        echo "    $1"
        echo ""
        exit 1
    fi
    return 0
}

func_build_core() {
    local ii=0
    while [ "x${LIST_BINFO_FILE_FULLNAME[ii]}" != "x" ]
    do
        echo "LIST_BINFO_FILE_FULLNAME[${ii}]: ${LIST_BINFO_FILE_FULLNAME[${ii}]}"
        func_build_single_binfo ${LIST_BINFO_FILE_FULLNAME[${ii}]} ${ii}
        ii=$(( ${ii} + 1 ))
    done
}

func_init_and_build_core() {
    func_build_env_init
    func_build_core
    func_build_env_deinit
    return 0
}
