#!/bin/bash

# reads binfo file and fetches latest sources from the upstream
# for the repository specified. If the repo has not been initialized
# earlier, then this will also checkout correct version, apply patches
# and initialize submodules
#
# Parameters
#   - path to binfo filename
source helpers/config.sh
source helpers/git_utils.sh

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
                    echo ""
                    echo "Creating repository source code directory: ${BINFO_APP_SRC_DIR}"
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
                echo "[${jj}]: Repository Source Code Fetch"
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
                    func_is_current_dir_a_git_submodule_dir #From helpers/git_utils.sh
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
                    func_is_current_dir_a_git_repo_dir #From git_utils.sh
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