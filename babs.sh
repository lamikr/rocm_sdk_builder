#!/bin/bash

#
# Copyright (c) 2024 by Mika Laitio <lamikr@gmail.com>
#
# License: GNU Lesser General Public License (LGPL), version 2.1 or later.
# See the lgpl.txt file in the root directory or <http://www.gnu.org/licenses/lgpl-2.1.html>.
#

# user configuration menu functionality
source binfo/user_config.sh

# allow enable doing some user specific extra actions before the build start
source ./envsetup_pre.sh

func_is_user_in_dev_kfd_render_group() {
    if [ -e /dev/kfd ]; then
        test -w /dev/kfd || {
            echo ""
            echo "You need to set write permissions to /dev/kfd device driver for the user."
            echo "This /dev/kfd is used by the ROCM applications to communicate with the AMD GPUs"
            local group_owner_name=$(stat -c "%G" /dev/kfd)
            if [ ${group_owner_name} = "render" ]; then
                echo "Add your username to group render with command: "
                echo "    sudo adduser $USERNAME render"
                echo "Usually you need then reboot to get change to in permissions to take effect"
                return 2
            else
                echo "Unusual /dev/kfd group owner instead of 'render': ${group_owner_name}"
                echo "Add your username to group ${group_owner_name} with command: "
                echo "    sudo adduser $USERNAME ${group_owner_name}"
                echo "Usually you need then reboot to get change to in permissions to take effect"
                return 3
            fi
        }
    else
        echo "Warning, /dev/kfd AMD GPU device driver does not exist"
        return 4
    fi
    return 0
}

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

func_is_current_dir_a_git_submodule_dir() {
    if [ -f .gitmodules ]; then
        echo ".gitmodules file exists"
        if [ "$(wc -w < .gitmodules)" -gt 0 ]; then
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

#if success function sets ret_val=0, in error cases ret_val=1
func_install_dir_init() {
    local ret_val
    local CUR_INSTALL_DIR_PATH="$1"

    ret_val=0
    if [ ! -z ${CUR_INSTALL_DIR_PATH} ]; then
        if [ -d ${CUR_INSTALL_DIR_PATH} ]; then
            if [ -w ${CUR_INSTALL_DIR_PATH} ]; then
                ret_val=0
            else
                echo "Warning, install direcory ${CUR_INSTALL_DIR_PATH} is not writable for the user ${USER}"
                sudo chown $USER:$USER ${CUR_INSTALL_DIR_PATH}
                if [ -w ${CUR_INSTALL_DIR_PATH} ]; then
                    echo "Install target directory owner changed with command 'sudo chown $USER:$USER ${CUR_INSTALL_DIR_PATH}'"
                    sleep 10
                    ret_val=0
                else
                    echo "Recommend using command 'sudo chown ${USER}:${USER} ${CUR_INSTALL_DIR_PATH}'"
                    ret_val=1
                fi
            fi
        else
            echo "Trying to create install target direcory: ${CUR_INSTALL_DIR_PATH}"
            mkdir -p ${CUR_INSTALL_DIR_PATH} 2> /dev/null
            if [ ! -d ${CUR_INSTALL_DIR_PATH} ]; then
                sudo mkdir -p ${CUR_INSTALL_DIR_PATH}
                if [ -d ${CUR_INSTALL_DIR_PATH} ]; then
                    echo "Install target directory created: 'sudo mkdir -p ${CUR_INSTALL_DIR_PATH}'"
                    sudo chown $USER:$USER ${CUR_INSTALL_DIR_PATH}
                    echo "Install target directory owner changed: 'sudo chown $USER:$USER ${CUR_INSTALL_DIR_PATH}'"
                    sleep 10
                    ret_val=0
                else
                    echo "Failed to create install target directory: ${CUR_INSTALL_DIR_PATH}"
                    ret_val=1
                fi
            else
                echo "Install target directory created: 'mkdir -p ${CUR_INSTALL_DIR_PATH}'"
                sleep 10
                ret_val=0
            fi
        fi
    else
        echo "Error, install dir parameter not specified: CUR_INSTALL_DIR_PATH"
        ret_val=1
    fi
    return ${ret_val}
}

func_is_current_dir_a_git_repo_dir() {
    local inside_git_repo
    inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
    if [ "$inside_git_repo" ]; then
        return 0  # is a git repo
    else
        return 1  # not a git repo
    fi
    #git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

func_repolist_binfo_list_print() {
    local jj=0

    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
        echo "binfo appname:         ${LIST_BINFO_APP_NAME[jj]}"
        echo "binfo file short name: ${LIST_BINFO_FILE_BASENAME[jj]}"
        echo "binfo file full name:  ${LIST_BINFO_FILE_FULLNAME[jj]}"
        echo "src clone dir:         ${LIST_APP_SRC_CLONE_DIR[jj]}"
        echo "src dir:               ${LIST_APP_SRC_DIR[jj]}"
        echo "patch dir:             ${LIST_APP_PATCH_DIR[jj]}"
        echo "upstream repository:   ${LIST_APP_UPSTREAM_REPO_URL[jj]}"
        echo ""
        ((jj++))
    done
}

func_repolist_upstream_remote_repo_add() {
    local jj

    # Display a message if src_projects directory does not exist
    jj=0
    if [ ! -d src_projects ]; then
        echo ""
        echo "Download of source projects will start shortly"
        echo "It will take up about 20 gb under 'src_projects' directory."
        echo "Advice:"
        echo "If you work with multible copies of this sdk,"
        echo "you could tar 'src_projects' and extract it manually for other SDK copies."
        echo ""
        sleep 3
    fi
    # Initialize git repositories and add upstream remote
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
    do
        if [ ! -d ${LIST_APP_SRC_CLONE_DIR[$jj]} ]; then
            echo "[${jj}]: Creating source code directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            sleep 0.1
            mkdir -p ${LIST_APP_SRC_CLONE_DIR[$jj]}
            # LIST_APP_ADDED_UPSTREAM_REPO parameter is used in
            # situations where same src_code directory is used for building multiple projects
            # with just different configure parameters (for example amd-fftw)
            # in this case we want to add upstream repo and apply patches only once
            LIST_APP_ADDED_UPSTREAM_REPO[$jj]=1
        fi
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            if [ ! -d ${LIST_APP_SRC_CLONE_DIR[$jj]}/.git ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo ""
                echo "[${jj}]: Repository Init"
                echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                sleep 0.5
                git init
                echo ${LIST_APP_UPSTREAM_REPO_URL[$jj]}
                git remote add upstream ${LIST_APP_UPSTREAM_REPO_URL[$jj]}
                LIST_APP_ADDED_UPSTREAM_REPO[$jj]=1
            else
                LIST_APP_ADDED_UPSTREAM_REPO[$jj]=0
                echo "[${jj}]: ${LIST_APP_SRC_CLONE_DIR[$jj]} ok"
            fi
        else
            LIST_APP_ADDED_UPSTREAM_REPO[$jj]=0
            echo "[${jj}]: ${LIST_APP_SRC_CLONE_DIR[$jj]} submodule ok"
        fi
        ((jj++))
        sleep 0.1
    done
    jj=0
    # Fetch updates and initialize submodules
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
    do
        #echo "LIST_APP_ADDED_UPSTREAM_REPO[$jj]: ${LIST_APP_ADDED_UPSTREAM_REPO[$jj]}"
        # check if directory was just created and git fetch needs to be done
        if [ ${LIST_APP_ADDED_UPSTREAM_REPO[$jj]} -eq 1 ]; then
            echo ""
            echo "[${jj}]: Source Fetch"
            echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
            echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
            echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            git fetch upstream
            if [ $? -ne 0 ]; then
                echo "git fetch failed: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                #exit 1
            fi
            git fetch upstream --force --tags
            git checkout "${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
            func_is_current_dir_a_git_submodule_dir
            ret_val=$?
            if [ ${ret_val} == "1" ]; then
                echo ""
                echo "[${jj}]: Submodule Init"
                echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                git submodule update --init --recursive
                if [ $? -ne 0 ]; then
                    echo "git submodule init and update failed: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                    exit 1
                fi
            fi
        fi
        ((jj++))
    done
    jj=0
    # apply patches if patch directory exists
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]
    do
        #echo "LIST_APP_ADDED_UPSTREAM_REPO[$jj]: ${LIST_APP_ADDED_UPSTREAM_REPO[$jj]}"
        # check if directory was just created and git am needs to be done
        if [ ${LIST_APP_ADDED_UPSTREAM_REPO[$jj]} -eq 1 ]; then
            TEMP_PATCH_DIR=${LIST_APP_PATCH_DIR[$jj]}
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            if [ -d "${TEMP_PATCH_DIR}" ]; then
                if [ ! -z "$(ls -A $TEMP_PATCH_DIR)" ]; then
                    echo ""
                    echo "[${jj}]: Applying Patches"
                    echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                    echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                    echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                    echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                    echo "Patch dir: ${TEMP_PATCH_DIR}"
                    git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
                    if [ $? -ne 0 ]; then
                        git am --abort
                        echo ""
                        echo "[${jj}]: Error, failed to Apply Patches"
                        echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                        echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                        echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                        echo "Version tag: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                        echo "Patch dir: ${TEMP_PATCH_DIR}"
                        echo ""
                        exit 1
                    else
                        echo "[${jj}]: Patches Applied: ${LIST_APP_SRC_CLONE_DIR}"
                    fi
                else
                   echo "[${jj}]: Warning, patch directory exists but is empty: ${TEMP_PATCH_DIR}"
                   sleep 2
                fi
            else
                true
                #echo "patch directory does not exist: ${TEMP_PATCH_DIR}"
                #sleep 2
            fi
        fi
        ((jj++))
    done
    echo ""
    echo "All new source code repositories added and initialized ok"
}

# reads binfo file and fetches latest sources from the upstream 
# for the repository specified. If the repo has not been initialized
# earlier, then this will also checkout correct version, apply patches
# and initialize submodules
#
# Parameters
#   - path to binfo filename
func_babs_init_and_fetch_single_repo_by_binfo() {
	func_envsetup_init
    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        echo "func_babs_handle_fetch param: $1"
        local APP_INFO_FULL_NAME=$1

        if [ -f ${APP_INFO_FULL_NAME} ]; then
            echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"

            unset BINFO_APP_NAME
            unset BINFO_APP_SRC_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

		    source ${APP_INFO_FULL_NAME}	
            local CUR_APP_UPSTREAM_REPO_DEFINED=0
            local CUR_APP_UPSTREAM_REPO_ADDED=0

            if [[ -n "${BINFO_APP_UPSTREAM_REPO_URL-}" ]]; then
                CUR_APP_UPSTREAM_REPO_DEFINED=1
            fi
            # Initialize git repositories and add upstream remote
            if [ "x${BINFO_APP_SRC_DIR}" != "x" ]; then
                if [ ! -d ${BINFO_APP_SRC_DIR} ]; then
                    echo "Creating source code directory: ${BINFO_APP_SRC_DIR}"
                    sleep 0.1
                    mkdir -p ${BINFO_APP_SRC_DIR}
                    # LIST_APP_ADDED_UPSTREAM_REPO parameter is used in
                    # situations where same src_code directory is used for building multiple projects
                    # with just different configure parameters (for example amd-fftw)
                    # in this case we want to add upstream repo and apply patches only once
                    CUR_APP_UPSTREAM_REPO_ADDED=1
                fi
                if [ "$CUR_APP_UPSTREAM_REPO_DEFINED" == "1" ]; then
                    if [ ! -d ${BINFO_APP_SRC_DIR}/.git ]; then
                        cd "${BINFO_APP_SRC_DIR}"
                        echo ""
                        echo "[${jj}]: Repository Init"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${BINFO_APP_SRC_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        sleep 0.5
                        git init
                        echo ${BINFO_APP_UPSTREAM_REPO_URL}
                        git remote add upstream ${BINFO_APP_UPSTREAM_REPO_URL}
                        CUR_APP_UPSTREAM_REPO_ADDED=1
                    else
                        CUR_APP_UPSTREAM_REPO_ADDED=0
                        echo "${BINFO_APP_SRC_DIR} ok"
                    fi
                else
                    CUR_APP_UPSTREAM_REPO_ADDED=0
                    echo "${BINFO_APP_SRC_DIR} submodule ok"
                fi
                sleep 0.1

                # Fetch updates and initialize submodules
                #echo "CUR_APP_UPSTREAM_REPO_ADDED: ${CUR_APP_UPSTREAM_REPO_ADDED}"
                # check if directory was just created and git fetch needs to be done
                echo ""
                echo "[${jj}]: Source Fetch"
                echo "Repository name: ${BINFO_APP_NAME}"
                echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                echo "Source directory: ${BINFO_APP_SRC_DIR}"
                echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                cd "${BINFO_APP_SRC_DIR}"
                git fetch upstream
                if [ $? -ne 0 ]; then
                    echo "git fetch failed: ${BINFO_APP_SRC_DIR}"
			        #exit 1
                fi
                git fetch upstream --force --tags
                # if this is new repository created before fetching, we want to 
                #     - checkout version by git tag
                #     - apply patches
                #     - fetch git submodules
                if [ ${CUR_APP_UPSTREAM_REPO_ADDED} -eq 1 ]; then
		            # checkout
		            git checkout "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"

                    # Apply patches if patch directory exists
                    # check if directory was just created and git am needs to be done
                    local CUR_APP_PATCH_DIR="${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}"
					local TEMP_PATCH_DIR=${CUR_APP_PATCH_DIR}
					cd "${BINFO_APP_SRC_DIR}"
					if [ -d "${TEMP_PATCH_DIR}" ]; then
						if [ ! -z "$(ls -A $TEMP_PATCH_DIR)" ]; then
							echo ""
							echo "[${jj}]: Applying Patches"
							echo "Repository name: ${BINFO_APP_NAME}"
							echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
							echo "Source directory: ${BINFO_APP_SRC_DIR}"
							echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
							echo "Patch dir: ${TEMP_PATCH_DIR}"
							git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
							if [ $? -ne 0 ]; then
								git am --abort
								echo ""
								echo "[${jj}]: Error, failed to Apply Patches"
								echo "Repository name: ${BINFO_APP_NAME}"
								echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
								echo "Source directory: ${BINFO_APP_SRC_DIR}"
								echo "Version tag: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
								echo "Patch dir: ${TEMP_PATCH_DIR}"
								echo ""
								exit 1
							else
								echo "Patches Applied: ${BINFO_APP_SRC_DIR}"
							fi
						else
							echo "Warning, patch directory exists but is empty: ${TEMP_PATCH_DIR}"
							sleep 2
						fi
					else
						true
						#echo "patch directory does not exist: ${TEMP_PATCH_DIR}"
						#sleep 2
					fi
                    # fetch git submodules
                    func_is_current_dir_a_git_submodule_dir
                    ret_val=$?
                    if [ ${ret_val} == "1" ]; then
                        echo ""
                        echo "[${jj}]: Submodule Init"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${BINFO_APP_SRC_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        git submodule update --init --recursive
                        if [ $? -ne 0 ]; then
                            echo "git submodule init and update failed: ${BINFO_APP_SRC_DIR}"
                            exit 1
                        fi
                    fi
                fi
            else
                echo "Failed to fetch sources, source directory is not specified"
            fi
        else
            echo "Failed to fetch sources, could not find binfo file: ${APP_INFO_FULL_NAME}"
        fi
    else
        echo "Failed to fetch sources, binfo file not defined"
    fi
}

func_repolist_fetch_top_repo() {
    local jj

    jj=0
    echo "func_repolist_fetch_top_repo started"
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]
    do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            if [ -d ${LIST_APP_SRC_CLONE_DIR[$jj]} ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo ""
                echo "[${jj}]: Repository Fetch"
                echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                git fetch upstream
                if [ $? -ne 0 ]; then
                    echo "git fetch failed: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                    exit 1
                fi
                git fetch upstream --force --tags
            else
                echo ""
                echo "[${jj}]: Failed to fetch source code for repository ${LIST_BINFO_APP_NAME[${jj}]}"
                echo "Source directory[$jj] not initialized with '-i' command:"
                echo "    ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                echo ""
                exit 1
            fi
        else
            echo "No repository defined for project in directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
        fi
        ((jj++))
    done
    echo ""
    echo "All source code repositories fetched ok"
}

func_babs_fetch_submodules_by_binfo() {
    local jj

    func_envsetup_init
    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        echo "func_babs_fetch_submodules_by_binfo param: $1"
        local APP_INFO_FULL_NAME=$1
        if [ -f ${APP_INFO_FULL_NAME} ]; then
            echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"

            unset BINFO_APP_NAME
            unset BINFO_APP_SRC_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

		    source ${APP_INFO_FULL_NAME}	

            if [ "x${BINFO_APP_SRC_DIR}" != "x" ]; then
                if [ -d ${BINFO_APP_SRC_DIR} ]; then
                    cd "${BINFO_APP_SRC_DIR}"
                    if [ -f .gitmodules ]; then
                        echo ""
                        echo "[${jj}]: Repository Submodule Update"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${BINFO_APP_SRC_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        sleep 0.3
                        git submodule foreach git reset --hard
                        git submodule update --recursive
                        git submodule foreach git fetch
                        if [ $? -ne 0 ]; then
                            echo ""
                            echo "[${jj}]: Error, failed to update repository submodules"
                            echo "Repository name: ${BINFO_APP_NAME}"
                            echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                            echo "Source directory: ${BINFO_APP_SRC_DIR}"
                            echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                            echo ""
                            exit 1
                         fi
                    else
                        echo ""
                        echo "[${jj}]: No Repository Submodules to Update"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${BINFO_APP_SRC_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        sleep 0.2
                    fi
                else
                    echo "Failed to fetch submodule sources, source directory does not exist"
                fi
            else
                echo "Failed to fetch submodule sources, source directory is not specified"
            fi
        else
            echo "Failed to fetch submodule sources, could not find binfo file: ${APP_INFO_FULL_NAME}"
        fi
    else
        echo "Failed to fetch submodule sources, binfo file not defined"
    fi
}

func_repolist_fetch_submodules() {
    local jj

    jj=0
    echo "func_repolist_fetch_submodules started"
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]
    do
        cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
        if [ -f .gitmodules ]; then
            echo ""
            echo "[${jj}]: Repository Submodule Update"
            echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
            echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
            echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
            sleep 0.3
            git submodule foreach git reset --hard
            git submodule update --recursive
            git submodule foreach git fetch
            if [ $? -ne 0 ]; then
                echo ""
                echo "[${jj}]: Error, failed to update repository submodules"
                echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                echo ""
                exit 1
            fi
        else
            echo ""
            echo "[${jj}]: No Repository Submodules to Update"
            echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
            echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
            echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
            sleep 0.2
        fi
        ((jj++))
    done
    echo ""
    echo "All submodules of source code repositories fetched ok"
}

# reads binfo file and checkouts repository specified there to tag specified there
# parameters
#   - path to binfo filename
func_babs_checkout_by_binfo() {
    func_envsetup_init
    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        echo "func_babs_handle_fetch param: $1"
        local APP_INFO_FULL_NAME=$1

        if [ -f ${APP_INFO_FULL_NAME} ]; then
            echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"

            unset BINFO_APP_NAME
            unset BINFO_APP_SRC_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

		    source ${APP_INFO_FULL_NAME}	

            if [ "x${BINFO_APP_SRC_DIR}" != "x" ]; then
                if [ -d ${BINFO_APP_SRC_DIR} ]; then
                    echo ""
                    echo "[$jj]: Repository Base Version Checkout"
                    echo "Repository name: ${BINFO_APP_NAME}"
                    echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                    echo "Source directory: ${BINFO_APP_SRC_DIR}"
                    echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                    sleep 0.1
                    cd "${BINFO_APP_SRC_DIR}"
                    git reset --hard
                    git checkout "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                    if [ $? -ne 0 ]; then
                        echo ""
                        echo "[${jj}]: Error, failed to checkout repository base version"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${BINFO_APP_SRC_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        echo ""
                        exit 1
                    else
                        echo ""
                        echo "[${jj}]: Checked out repository base version"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${BINFO_APP_SRC_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        echo ""
                    fi
                else
                    echo "Error, source directory where fetch repository does not exist. ${BINFO_APP_SRC_DIR}"
                fi
            else
                echo "Error, source directory where fetch repository not specified"
            fi
        else
            echo "Failed to checkout, could not find binfo file: ${APP_INFO_FULL_NAME}"
        fi
    else
        echo "Failed to checkout, binfo file not defined"
    fi
}

func_repolist_checkout_default_versions() {
    local jj

    jj=0
    echo "func_repolist_checkout_default_versions started"
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]
    do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            echo ""
            echo "[$jj]: Repository Base Version Checkout"
            echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
            echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
            echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
            sleep 0.1
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            git reset --hard
            git checkout "${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
            if [ $? -ne 0 ]; then
                echo ""
                echo "[${jj}]: Error, failed to checkout repository base version"
                echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                echo ""
                exit 1
            fi            
        fi
        ((jj++))
    done
    echo ""
    echo "All source code repositories checked out to default tag version ok"
    echo "Use following command to apply rocm_sdk_builder patches before starting the build:"
    echo "    ./babs.sh -ap"
}

# check that repositories do not
# - have uncommitted patches
# - have changes that diff from original patches
# - are not in state where am apply has failed
func_repolist_is_changes_committed() {
    local jj

    jj=0
    echo "func_repolist_is_changes_committed started"
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]
    do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir
            if [ $? -eq 0 ]; then
                if [[ `git status --porcelain --ignore-submodules=all` ]]; then
                    echo "git status error: " ${LIST_APP_SRC_CLONE_DIR[$jj]}
                    exit 1
                else
                    # No changes
                    #echo "git status ok: " ${LIST_APP_SRC_CLONE_DIR[$jj]}
                    #if [[ `git am --show-current-patch > /dev/null ` ]]; then
                    git status | grep "git am --skip" > /dev/null
                    if [ ! "$?" == "1" ]; then
                        echo "git am error: " ${LIST_APP_SRC_CLONE_DIR[$jj]}
                        exit 1
                    else
                        echo "git am ok: " ${LIST_APP_SRC_CLONE_DIR[$jj]}
                    fi
                fi
            else
                echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
            fi
        fi
        ((jj++))
    done
}

func_repolist_appliad_patches_save() {
    local jj

    jj=0
    cmd_diff_check=(git diff --exit-code)
    DATE=`date "+%Y%m%d"`
    DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S"`
    PATCHES_DIR=$(pwd)/patches/${DATE_WITH_TIME}
    echo ${PATCHES_DIR}
    mkdir -p ${PATCHES_DIR}
    if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
        cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
        func_is_current_dir_a_git_repo_dir
        if [ $? -eq 0 ]; then
            "${cmd_diff_check[@]}" &>/dev/null
            if [ $? -ne 0 ]; then
                fname=$(basename -- "${LIST_APP_SRC_CLONE_DIR[jj]}").patch
                echo "diff: ${fname}"
                "${cmd_diff_check[@]}" >${PATCHES_DIR}/${fname}
            else
                true
                #echo "${LIST_APP_SRC_CLONE_DIR[jj]}"
            fi
        else
            echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
        fi
    fi
    ((jj++))
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
    do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
            func_is_current_dir_a_git_repo_dir
            if [ $? -eq 0 ]; then
                "${cmd_diff_check[@]}" &>/dev/null
                if [ $? -ne 0 ]; then
                    fname=$(basename -- "${LIST_APP_SRC_CLONE_DIR[jj]}").patch
                    echo "diff: ${DATE_WITH_TIME}/${fname}"
                    "${cmd_diff_check[@]}" >${PATCHES_DIR}/${fname}
                else
                    true
                    #echo "${LIST_APP_SRC_CLONE_DIR[jj]}"
                fi
            else
                echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
            fi
        fi
        ((jj++))
    done
    echo "patches generated: ${PATCHES_DIR}"
}

func_repolist_export_version_tags_to_file() {
    local jj

    jj=0
    if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
        cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
        func_is_current_dir_a_git_repo_dir
        if [ $? -eq 0 ]; then
            GITHASH=$(git rev-parse --short=8 HEAD)
            echo "${GITHASH} ${LIST_BINFO_APP_NAME[${jj}]}" > ${FNAME_REPO_REVS_NEW}
        else
            echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
        fi
    fi
    ((jj++))
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
    do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir
            if [ $? -eq 0 ]; then
                GITHASH=$(git rev-parse --short=8 HEAD 2>/dev/null)
                echo "${GITHASH} ${LIST_BINFO_APP_NAME[${jj}]}" >> ${FNAME_REPO_REVS_NEW}
            else
                echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
            fi
        fi
        ((jj++))
    done
    echo "repo hash list generated: ${FNAME_REPO_REVS_NEW}"
}

func_repolist_find_app_index_by_app_name() {
    local temp_search_name="$1"
    local kk

    RET_INDEX_BY_NAME=-1
    kk=0
    while [[ -n "${LIST_BINFO_APP_NAME[kk]}" ]]; do
        if [[ "${LIST_BINFO_APP_NAME[kk]}" == "${temp_search_name}" ]]; then
            RET_INDEX_BY_NAME=$kk
            break
        fi
        ((kk++))
    done
}

func_repolist_fetch_by_version_tag_file() {
    echo "func_repolist_fetch_by_version_tag_file"

    if [ ! -z $1 ]; then
        REPO_UPSTREAM_NAME=$1
    else
        REPO_UPSTREAM_NAME=--all
    fi
    jj=0
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
    do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            echo "repo dir: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir
            if [ $? -eq 0 ]; then
                echo "${LIST_BINFO_APP_NAME[jj]}: git fetch ${REPO_UPSTREAM_NAME}"
                git fetch ${REPO_UPSTREAM_NAME}
                if [ $? -ne 0 ]; then
                    echo "git fetch ${REPO_UPSTREAM_NAME} failed: " ${LIST_BINFO_APP_NAME[jj]}
                    #exit 1
                fi
                if [ -f .gitmodules ]; then
                    #echo "submodule update"
                    git submodule update --recursive
                fi
                sleep 1
            else
                echo "Not a git repository: " ${LIST_APP_SRC_CLONE_DIR[jj]}
                exit 1
            fi
        else
            echo "upstream fetch all skipped, no repository defined: " ${LIST_BINFO_APP_NAME[$jj]}
        fi
        ((jj++))
    done
}

func_repolist_version_tag_read_to_array_list_from_file() {
    echo "func_repolist_version_tag_read_to_array_list_from_file"

    LIST_REPO_REVS_CUR=()
    LIST_TEMP=()
    LIST_TEMP=(`cat "${FNAME_REPO_REVS_CUR}"`)
    echo "reading: ${FNAME_REPO_REVS_CUR}"
    jj=0
    while [ "x${LIST_TEMP[jj]}" != "x" ]
    do
        TEMP_HASH=${LIST_TEMP[$jj]}
        ((jj++))
        #echo "Element [$jj]: ${LIST_TEMP[$jj]}"
        TEMP_NAME=${LIST_TEMP[$jj]}
        #echo "Element [$jj]: ${TEMP_NAME}"
        func_repolist_find_app_index_by_app_name ${TEMP_NAME}
        if [ ${RET_INDEX_BY_NAME} -ge 0 ]; then
            LIST_REPO_REVS_CUR[$RET_INDEX_BY_NAME]=${TEMP_HASH}
            if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$RET_INDEX_BY_NAME]]}" == "1" ]; then
                echo "find_index_by_name ${TEMP_NAME}: " ${LIST_REPO_REVS_CUR[$RET_INDEX_BY_NAME]} ", repo: " ${LIST_APP_UPSTREAM_REPO_URL[$RET_INDEX_BY_NAME]}
            fi
        else
            echo "Find_index_by_name failed for name: " ${TEMP_NAME}
            exit 1
        fi
        ((jj++))
    done
}

func_repolist_checkout_by_version_tag_file() {
    echo "func_repolist_checkout_by_version_tag_file"
    func_repolist_fetch_by_version_tag_file

    # Read hashes from the stored txt file
    func_repolist_version_tag_read_to_array_list_from_file
    jj=0
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
    do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir
            if [ $? -eq 0 ]; then
                echo "git checkout: " ${LIST_BINFO_APP_NAME[jj]}
                git checkout ${LIST_REPO_REVS_CUR[$jj]}
                if [ $? -ne 0 ]; then
                    echo "repo checkout failed: " ${LIST_BINFO_APP_NAME[jj]}
                    echo "    revision: " ${LIST_REPO_REVS_CUR[$jj]}
                    exit 1
                else
                    echo "repo checkout ok: " ${LIST_BINFO_APP_NAME[jj]}
                    echo "    revision: " ${LIST_REPO_REVS_CUR[$jj]}
                fi
            else
                echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
            fi
        else
            echo "upstream repo checkout skipped, no repository defined: " ${LIST_BINFO_APP_NAME[$jj]}
        fi
        ((jj++))
    done
}

func_babs_apply_patches_by_binfo() {
    func_envsetup_init
    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        echo "func_babs_handle_fetch param: $1"
        local APP_INFO_FULL_NAME=$1

        if [ -f ${APP_INFO_FULL_NAME} ]; then
            echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"

            unset BINFO_APP_NAME
            unset BINFO_APP_SRC_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

		    source ${APP_INFO_FULL_NAME}	
            local CUR_APP_PATCH_DIR="${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}"

            if [ "x${BINFO_APP_SRC_DIR}" != "x" ]; then
                if [ -d ${BINFO_APP_SRC_DIR} ]; then
                    cd "${BINFO_APP_SRC_DIR}"
                    func_is_current_dir_a_git_repo_dir
                    if [ $? -eq 0 ]; then
                        echo "patch dir: ${CUR_APP_PATCH_DIR}"
                        if [ -d "${CUR_APP_PATCH_DIR}" ]; then
                            if [ ! -z "$(ls -A $CUR_APP_PATCH_DIR)" ]; then
                                echo ""
                                echo "[${jj}]: Repository Apply Patches"
                                echo "Repository name: ${BINFO_APP_NAME}"
                                echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                                echo "Source directory: ${BINFO_APP_SRC_DIR}"
                                echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                                sleep 0.1
                                git am --keep-cr "${CUR_APP_PATCH_DIR}"/*.patch
                                if [ $? -ne 0 ]; then
                                    git am --abort
                                    echo ""
                                    echo "[$jj]: Error, failed to apply patches"
                                    echo "Repository name: ${BINFO_APP_NAME}"
                                    echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                                    echo "Source directory: ${BINFO_APP_SRC_DIR}"
                                    echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                                    echo "Patch directory: ${CUR_APP_PATCH_DIR}"
                                    echo ""
                                    exit 1
                                else
                                    echo "[$jj]: Patches applied ok: ${BINFO_APP_SRC_DIR}"
                                    #echo "git am ok"
                                fi
                            else
                                echo "Warning, empty patch directory: ${CUR_APP_PATCH_DIR}"
                                sleep 2
                            fi
                        else
                            true
                            echo "${LIST_BINFO_APP_NAME[${jj}]}: No patches to apply"
                            #echo "patch directory does not exist: ${CUR_APP_PATCH_DIR}"
                            #sleep 2
                        fi
                    else
                        echo "Failed to apply patches, not a git repository: ${BINFO_APP_SRC_DIR}"
                        sleep 2
                    fi
                else
                    echo "Failed to apply patches, source directory does not exist: ${BINFO_APP_SRC_DIR}"
                fi
            else
                echo "Failed to apply patches, source directory not defined"
            fi
        else
            echo "Failed to apply patches, binfo file does not exist"
        fi
    else
        echo "Failed to apply patches, binfo file not defined"
    fi
    echo ""
    echo "Patches applied ok"
}

func_repolist_apply_patches() {
    declare -A DICTIONARY_PATCHED_PROJECTS
    echo "func_repolist_apply_patches"
    jj=0
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
    do
        if [ -z ${DICTIONARY_PATCHED_PROJECTS[${LIST_BINFO_APP_NAME[${jj}]}]} ]; then
            if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
                func_is_current_dir_a_git_repo_dir
                if [ $? -eq 0 ]; then
                    TEMP_PATCH_DIR=${LIST_APP_PATCH_DIR[$jj]}
                    echo "patch dir: ${TEMP_PATCH_DIR}"
                    if [ -d "${TEMP_PATCH_DIR}" ]; then
                        if [ ! -z "$(ls -A $TEMP_PATCH_DIR)" ]; then
                            echo ""
                            echo "[$jj]: Repository Apply Patches"
                            echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                            echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                            echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                            echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                            sleep 0.1
                            git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
                            if [ $? -ne 0 ]; then
                                git am --abort
                                echo ""
                                echo "[$jj]: Error, failed to apply patches"
                                echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
                                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                                echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                                echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                                echo "Patch directory: ${TEMP_PATCH_DIR}"
                                echo ""
                                exit 1
                            else
                                echo "[$jj]: Patches applied ok: ${LIST_APP_SRC_CLONE_DIR[${jj}]}"
                                #echo "git am ok"
                            fi
                            DICTIONARY_PATCHED_PROJECTS[${LIST_BINFO_APP_NAME[${jj}]}]=1
                        else
                            echo "Warning, empty patch directory: ${TEMP_PATCH_DIR}"
                            sleep 2
                        fi
                    else
                        true
                        echo "${LIST_BINFO_APP_NAME[${jj}]}: No patches to apply"
                        #echo "patch directory does not exist: ${TEMP_PATCH_DIR}"
                        #sleep 2
                    fi
                    sleep 0.1
                else
                    echo "Warning, not a git repository: ${LIST_APP_SRC_CLONE_DIR[${jj}]}"
                    sleep 2
                fi
            else
                echo "repo am paches skipped, no repository defined: ${LIST_BINFO_APP_NAME[${jj}]}"
            fi
        else
            echo "[$jj]: ${LIST_BINFO_APP_NAME[${jj}]}: patches already applied, skipping"
        fi
        ((jj++))
    done
    echo ""
    echo "Patches applied to all source code repositories ok"
}

func_repolist_checkout_by_version_param() {
    if [ ! -z $1 ]; then
        CHECKOUT_VERSION=$1
        echo "func_repolist_checkout_by_version_param: ${CHECKOUT_VERSION}"
        jj=0
        while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]
        do
            if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
                func_is_current_dir_a_git_repo_dir
                if [ $? -eq 0 ]; then
                    #echo "git checkout ${CHECKOUT_VERSION}: ${LIST_BINFO_APP_NAME[jj]}"
                    git checkout ${CHECKOUT_VERSION}
                    if [ $? -ne 0 ]; then
                        echo "git checkout failed: " ${LIST_BINFO_APP_NAME[jj]}
                        echo "   version: " ${CHECKOUT_VERSION}
                    else
                        true
                        #echo "repo checkout ok: " ${LIST_BINFO_APP_NAME[jj]}
                        #echo "   version: " ${CHECKOUT_VERSION}
                    fi
                else
                    echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
                fi
            else
                echo "upstream repo checkout skipped, no repository defined: " ${LIST_BINFO_APP_NAME[$jj]}
            fi
            ((jj++))
        done
    else
        echo "    Error, git version parameter missing"
        exit
    fi
}

#this method not used at the moment and needs refactoring if needed in future
func_repolist_download() {
    func_build_version_init
    func_envsetup_init
    func_repolist_binfo_list_print
    func_repolist_upstream_remote_repo_add
    func_repolist_is_changes_committed
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

func_user_help_print() {
    func_build_system_name_and_version_print
    echo "babs (babs ain't patch build system)"
    echo "usage:"
    echo "-h or --help:           Show this help"
    echo "-c or --configure       Show list of GPU's for which the the build is optimized"
    echo "-i or --init:           Download git repositories listed in binfo directory to 'src_projects' directory"
    echo "                        and apply all patches from 'patches' directory."
    echo "                        Optional parameter: binfo/myapp.binfo"
    echo "-ap or --apply_patches: Scan 'patches/rocm-version' directory and apply each patch"
    echo "                        on top of the repositories in 'src_projects' directory."
    echo "                        Optional parameter: binfo/myapp.binfo"
    echo "-co or --checkout:      Checkout version listed in binfo files for each git repository in src_projects directory."
    echo "                        Apply of patches of top of the checked out version needs to be performed separately"
    echo "                        with '-ap' command."
    echo "                        Optional parameter: binfo/myapp.binfo"
    echo "-f or --fetch:          Fetch latest source code for all repositories."
    echo "                        Checkout of fetched sources needs to be performed separately with '-co' command."
    echo "                        Possible subprojects needs to be fetched separately with '-fs' command."
    echo "                        (after '-co' and '-ap')"
    echo "                        Optional parameter: binfo/myapp.binfo"
    echo "-fs or --fetch_submod:  Fetch and checkout git submodules for all repositories which have them."
    echo "                        Optional parameter: binfo/myapp.binfo"    
    echo "-b or --build:          Start or continue the building of rocm_sdk."
    echo "                        Build files are located under 'builddir' directory and install is performed"
    echo "                        on '/opt/rocm_sdk_version' directory."
    echo "                        Optional parameter: binfo/myapp.binfo"
    echo "                        If source directory does not exist, it will first download and apply patches if them are available"
    echo "-v or --version:        Show babs build system version information"
    #echo "-cp or --create_patches: generate patches by checking git diff for each repository"
    #echo "-g or --generate_repo_list: generates repo_list_new.txt file containing current repository revision hash for each project"
    #echo "-s or --sync: checkout all repositories to base git hash"
    echo ""
    if [ ! -d src_projects ]; then
        echo ""
        echo "----------------Advice ---------------"
        echo "No ROCm project source codes detected in 'src_projects 'directory."
        echo "I recommend downloading them first with command './babs.sh -i'"
        echo ""
        echo "Projects will be loaded to 'src_projects' directory"
        echo "and will require about 20gb of space."
        echo "If download of some projects fails, you can issue './babs.sh -i' command again"
        echo "--------------------------------------"
        echo ""
    else
        if [ ! -d builddir ]; then
        echo ""
        echo "----------------Advice ---------------"
        echo "No ROCm 'builddir' directory detected."
        echo "Once projects source code has been downloaded with './babs.sh -i' command"
        echo "you can start building with command './babs.sh -b'"
        echo "--------------------------------------"
        echo ""
        fi
    fi
    exit 0
}

func_is_git_configured() {
    local GIT_USER_NAME
    local GIT_USER_EMAIL

    GIT_USER_NAME=$(git config --get user.name)
    if [[ -n "$GIT_USER_NAME" ]]; then
        GIT_USER_EMAIL=$(git config --get user.email)
        if [[ -n "$GIT_USER_EMAIL" ]]; then
            return 0
        else
            echo ""
            echo "You need to configure git user's email address. Example command:"
            echo "    git config --global user.email \"john.doe@emailserver.com\""
            echo ""
            exit 2
        fi
    else
        echo ""
        echo "You need to configure git user's name and email address. Example commands:"
        echo "    git config --global user.name \"John Doe\""
        echo "    git config --global user.email \"john.doe@emailserver.com\""
        echo ""
        exit 2
    fi
}

func_babs_handle_build() {
	func_env_variables_print
	func_install_dir_init ${INSTALL_DIR_PREFIX_SDK_AI_MODELS}
	func_install_dir_init ${INSTALL_DIR_PREFIX_SDK_ROOT}
	local ret_val=$?
	if [[ $ret_val -eq 0 ]]; then
        if [[ -n "$1" ]]; then
            echo "func_build param: $1"
            source ./build/build_func.sh
            func_init_and_build_single_binfo $1
        else
            echo "func_build no params"
            source ./build/build_core.sh
        fi
        res=$?
		if [[ $res -eq 0 ]]; then
			echo -e "\nROCM SDK build and install ready"
			func_is_user_in_dev_kfd_render_group
			res=$?
			if [ ${res} -eq 0 ]; then
				echo "You can use the following commands to test your gpu is detected:"
			else
				echo "After fixing /dev/kff permission problems, you can use the following commands to test that your gpu"
			fi
			echo ""
			echo "    source ${INSTALL_DIR_PREFIX_SDK_ROOT}/bin/env_rocm.sh"
			echo "    rocminfo"
			echo ""
		else
			echo -e "Failed to build ROCM_SDK_BUILDER"
			echo ""
		fi        
    fi
}

func_handle_user_configure_help_and_version_args() {
    for arg in "${LIST_USER_CMD_ARGS[@]}"; do
        case $arg in
            -c|--configure)
                func_build_cfg_user
                exit 0
                ;;
            -h|--help)
                func_user_help_print
                exit 0
                ;;
            -v|--version)
                func_build_system_name_and_version_print
                exit 0
                ;;
        esac
    done
}

func_handle_user_command_args() {
    local ii=0
    local res
    local ARG__USER_CMD
    local ARG__USER_CMD_PARAM1

    while [[ -n "${LIST_USER_CMD_ARGS[ii]}" ]]; do
        unset ARG__USER_CMD_PARAM1
        ARG__USER_CMD=${LIST_USER_CMD_ARGS[ii]}
        if [[ ${ARG__USER_CMD:0:1} == '-' ]]; then
            echo "ARG__USER_CMD: ${ARG__USER_CMD}"
            if [ -n "${LIST_USER_CMD_ARGS[ii + 1]}" ]; then
                ARG__USER_CMD_PARAM1=${SDK_ROOT_DIR}/${LIST_USER_CMD_ARGS[ii + 1]}
                if [[ ! ${ARG__USER_CMD_PARAM1:0:1} == '-' ]]; then
                    # should be a valid parameter for command
                    ((ii++))
                    echo "ARG__USER_CMD_PARAM1: ${ARG__USER_CMD_PARAM1}"
                else
                    # another command starting with "-"-character
                    unset ARG__USER_CMD_PARAM1
                    echo "ARG__USER_CMD_PARAM1 not provided for ${ARG__USER_CMD}"
                fi
            fi    
            case "${ARG__USER_CMD}" in
                -ap|--apply_patches)
                    func_is_git_configured
                    if [[ -n "${ARG__USER_CMD_PARAM1}" ]]; then
                        func_babs_apply_patches_by_binfo ${ARG__USER_CMD_PARAM1}
                    else
                        func_repolist_apply_patches
                    fi
                    exit 0
                    ;;
                -b|--build)
		            echo "build"
		            func_babs_handle_build ${ARG__USER_CMD_PARAM1}
		            exit 0
                    ;;
                -cp|--create_patches)
                    func_repolist_appliad_patches_save
                    exit 0
                    ;;
                -co|--checkout)
                    if [[ -n "${ARG__USER_CMD_PARAM1}" ]]; then
                        func_babs_checkout_by_binfo ${ARG__USER_CMD_PARAM1}
                    else
                        func_repolist_checkout_default_versions
                    fi
                    exit 0
                    ;;
                -f|--fetch)
                    if [[ -n "${ARG__USER_CMD_PARAM1}" ]]; then
                        func_babs_init_and_fetch_single_repo_by_binfo ${ARG__USER_CMD_PARAM1}
                    else
                        func_repolist_fetch_top_repo
                    fi
                    exit 0
                    ;;
                -fs|--fetch_submod)
                    if [[ -n "${ARG__USER_CMD_PARAM1}" ]]; then
                        func_babs_fetch_submodules_by_binfo ${ARG__USER_CMD_PARAM1}
                    else
                        func_repolist_fetch_submodules
                    fi
                    exit 0
                    ;;
                -g|--generate_repo_list)
                    func_repolist_export_version_tags_to_file
                    exit 0
                    ;;
                -i|--init)
                    func_is_git_configured
                    if [[ -n "${ARG__USER_CMD_PARAM1}" ]]; then
                        source ./build/build_func.sh
                        func_upstream_remote_repo_add_by_binfo ${ARG__USER_CMD_PARAM1}
                    else
                        func_repolist_upstream_remote_repo_add
                    fi                    
                    exit 0
                    ;;
                -s|--sync)
                    func_repolist_checkout_by_version_tag_file
                    exit 0
                    ;;
                *)
                    echo "Unknown user command parameter: ${LIST_USER_CMD_ARGS[ii]}"
                    exit 0
                    ;;
            esac
        fi
        ((ii++))
    done
}

if [ "$#" -eq 0 ]; then
    func_user_help_print
else
    LIST_USER_CMD_ARGS=( "$@" )
    # Initialize build version
    func_build_version_init
    # Handle help and version commands before prompting the user config menu
    func_handle_user_configure_help_and_version_args
    # Initialize environment setup
    func_envsetup_init
    # Handle user command arguments
    func_handle_user_command_args
fi
