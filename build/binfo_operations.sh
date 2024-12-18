#!/bin/bash

# reads binfo file and fetches latest sources from the upstream
# for the repository specified. If the repo has not been initialized
# earlier, then this will also checkout correct version, apply patches
# and initialize submodules
#
# Parameters
#   - path to binfo filename
source build/config.sh
source build/git_utils.sh

func_babs_init_and_fetch_by_binfo() {
	local skip_patches

    skip_patches=0
    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        if [[ -n "$3" ]]; then
            skip_patches=$3
        fi
        echo "func_babs_init_and_fetch_by_binfo param: $1"
        local APP_INFO_FULL_NAME=$1

        if [ -f ${APP_INFO_FULL_NAME} ]; then
            echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"

            unset BINFO_APP_NAME
            unset BINFO_APP_SRC_DIR
            unset BINFO_APP_SRC_CLONE_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

            source ${APP_INFO_FULL_NAME}

            local CUR_APP_UPSTREAM_REPO_DEFINED=0
            local CUR_APP_UPSTREAM_REPO_ADDED=0
            local CUR_APP_SRC_CLONE_DIR
            if [[ -n "${BINFO_APP_SRC_CLONE_DIR}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_CLONE_DIR}"
            elif [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_DIR}"
            else
                echo "Error: BINFO_APP_SRC_DIR not defined in ${APP_INFO_FULL_NAME}"
                exit 1
            fi

            if [[ -n "${BINFO_APP_UPSTREAM_REPO_URL-}" ]]; then
                CUR_APP_UPSTREAM_REPO_DEFINED=1
            fi
            # Initialize git repositories and add upstream remote
            if [ "x${CUR_APP_SRC_CLONE_DIR}" != "x" ]; then
                if [ ! -d ${CUR_APP_SRC_CLONE_DIR} ]; then
                    echo ""
                    echo "Creating repository source code directory: ${CUR_APP_SRC_CLONE_DIR}"
                    sleep 0.1
                    mkdir -p ${CUR_APP_SRC_CLONE_DIR}
                    # LIST_APP_ADDED_UPSTREAM_REPO parameter is used in
                    # situations where same src_code directory is used for building multiple projects
                    # with just different configure parameters (for example amd-fftw)
                    # in this case we want to add upstream repo and apply patches only once
                    CUR_APP_UPSTREAM_REPO_ADDED=1
                fi
                if [ "$CUR_APP_UPSTREAM_REPO_DEFINED" == "1" ]; then
                    if [ ! -d ${CUR_APP_SRC_CLONE_DIR}/.git ]; then
                        cd "${CUR_APP_SRC_CLONE_DIR}"
                        echo ""
                        echo "[${jj}]: Repository Init"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        sleep 0.5
                        git init
                        echo ${BINFO_APP_UPSTREAM_REPO_URL}
                        git remote add upstream ${BINFO_APP_UPSTREAM_REPO_URL}
                        CUR_APP_UPSTREAM_REPO_ADDED=1
                    else
                        CUR_APP_UPSTREAM_REPO_ADDED=0
                        echo "${CUR_APP_SRC_CLONE_DIR} ok"
                    fi
                else
                    CUR_APP_UPSTREAM_REPO_ADDED=0
                    echo "${CUR_APP_SRC_CLONE_DIR} submodule ok"
                fi
                sleep 0.1

                # Fetch updates and initialize submodules
                #echo "CUR_APP_UPSTREAM_REPO_ADDED: ${CUR_APP_UPSTREAM_REPO_ADDED}"
                # check if directory was just created and git fetch needs to be done
                echo ""
                echo "[${jj}]: Repository Source Code Fetch"
                echo "Repository name: ${BINFO_APP_NAME}"
                echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                cd "${CUR_APP_SRC_CLONE_DIR}"
                git fetch upstream
                if [ $? -ne 0 ]; then
                    echo "git fetch failed: ${CUR_APP_SRC_CLONE_DIR}"
                    #exit 1
                fi
                git fetch upstream --force --tags
                if [ ${CUR_APP_UPSTREAM_REPO_ADDED} -eq 0 ]; then
                    # for old repositories having submodules we just fetch them one by one
                    func_is_current_dir_a_git_submodule_dir #From build/git_utils.sh
                    cur_res=$?
                    if [ ${cur_res} == "1" ]; then
                        git submodule foreach git fetch
                        git submodule foreach git fetch --force --tags
                    fi
                else
                    # if this is new repository created before fetching, we want to
                    #     - checkout version by git tag
                    #     - apply patches
                    #     - fetch git submodules
                    # checkout
                    git checkout "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"

                    if [ ${skip_patches} -eq 0 ]; then
                        # Apply patches if patch directory exist
                        # check if directory was just created and git am needs to be done
                        local CUR_APP_PATCH_DIR="${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}"
                        local TEMP_PATCH_DIR=${CUR_APP_PATCH_DIR}
                        cd "${CUR_APP_SRC_CLONE_DIR}"
                        if [ -d "${TEMP_PATCH_DIR}" ]; then
                            if [ ! -z "$(ls -A $TEMP_PATCH_DIR)" ]; then
                                echo ""
                                echo "[${jj}]: Applying Patches"
                                echo "Repository name: ${BINFO_APP_NAME}"
                                echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                                echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                                echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                                echo "Patch dir: ${TEMP_PATCH_DIR}"
                                git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
                                if [ $? -ne 0 ]; then
                                    git am --abort
                                    echo ""
                                    echo "[${jj}]: Error, failed to Apply Patches"
                                    echo "Repository name: ${BINFO_APP_NAME}"
                                    echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                                    echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                                    echo "Version tag: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                                    echo "Patch dir: ${TEMP_PATCH_DIR}"
                                    echo ""
                                    exit 1
                                else
                                    echo "Patches Applied: ${CUR_APP_SRC_CLONE_DIR}"
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
                    else
                        # skip patches because this is -co or -ca command and we will apply them later
                        true
                    fi
                    # fetch git submodules
                    func_is_current_dir_a_git_submodule_dir #From build/git_utils.sh
                    cur_res=$?
                    if [ ${cur_res} == "1" ]; then
                        echo ""
                        echo "[${jj}]: Submodule Init"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        git submodule update --init --recursive
                        if [ $? -ne 0 ]; then
                            echo "git submodule init and update failed: ${CUR_APP_SRC_CLONE_DIR}"
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
    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        echo "func_babs_apply_patches_by_binfo param: $1"
        local APP_INFO_FULL_NAME=$1

        if [ -f ${APP_INFO_FULL_NAME} ]; then
            echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"

            unset BINFO_APP_NAME
            unset BINFO_APP_SRC_DIR
            unset BINFO_APP_SRC_CLONE_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

            source ${APP_INFO_FULL_NAME}

            local CUR_APP_PATCH_DIR="${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}"
            local CUR_APP_SRC_CLONE_DIR
            if [[ -n "${BINFO_APP_SRC_CLONE_DIR}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_CLONE_DIR}"
            elif [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_DIR}"
            else
                echo "Error: BINFO_APP_SRC_DIR not defined in ${APP_INFO_FULL_NAME}"
                exit 1
            fi

            if [ "x${CUR_APP_SRC_CLONE_DIR}" != "x" ]; then
                if [ -d ${CUR_APP_SRC_CLONE_DIR} ]; then
                    cd "${CUR_APP_SRC_CLONE_DIR}"
                    func_is_current_dir_a_git_repo_dir #From git_utils.sh
                    if [ $? -eq 0 ]; then
                        echo "patch dir: ${CUR_APP_PATCH_DIR}"
                        if [ -d "${CUR_APP_PATCH_DIR}" ]; then
                            if [ ! -z "$(ls -A $CUR_APP_PATCH_DIR)" ]; then
                                echo ""
                                echo "[${jj}]: Repository Apply Patches"
                                echo "Repository name: ${BINFO_APP_NAME}"
                                echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                                echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                                echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                                sleep 0.1
                                git am --keep-cr "${CUR_APP_PATCH_DIR}"/*.patch
                                if [ $? -ne 0 ]; then
                                    git am --abort
                                    echo ""
                                    echo "[$jj]: Error, failed to apply patches"
                                    echo "Repository name: ${BINFO_APP_NAME}"
                                    echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                                    echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                                    echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                                    echo "Patch directory: ${CUR_APP_PATCH_DIR}"
                                    echo ""
                                    exit 1
                                else
                                    echo "[$jj]: Patches applied ok: ${CUR_APP_SRC_CLONE_DIR}"
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
                        echo "Failed to apply patches, not a git repository: ${CUR_APP_SRC_CLONE_DIR}"
                        sleep 2
                    fi
                else
                    echo "Failed to apply patches, source directory does not exist: ${CUR_APP_SRC_CLONE_DIR}"
                fi
            else
                echo "Failed to apply patches, source directory not defined"
            fi
        else
            pwd
            echo "Failed to apply patches, binfo file does not exist. ${APP_INFO_FULL_NAME}"
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
#   - repository number to be checked out
func_babs_checkout_by_binfo_once() {
    local ret_val=0

    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        echo "func_babs_checkout_by_binfo_once param: $1"
        local APP_INFO_FULL_NAME=$1

        if [ -f ${APP_INFO_FULL_NAME} ]; then
            echo "APP_INFO_FULL_NAME: ${APP_INFO_FULL_NAME}"

            unset BINFO_APP_NAME
            unset BINFO_APP_SRC_DIR
            unset BINFO_APP_SRC_CLONE_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

            source ${APP_INFO_FULL_NAME}

            local CUR_APP_SRC_CLONE_DIR
            if [[ -n "${BINFO_APP_SRC_CLONE_DIR}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_CLONE_DIR}"
            elif [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_DIR}"
            else
                echo "Error: BINFO_APP_SRC_DIR not defined in ${APP_INFO_FULL_NAME}"
                return 1
            fi

            if [ "x${CUR_APP_SRC_CLONE_DIR}" != "x" ]; then
                if [ -d ${CUR_APP_SRC_CLONE_DIR} ]; then
                    if [ "x${BINFO_APP_UPSTREAM_REPO_URL}" != "x" ]; then
                        echo ""
                        echo "[$jj]: Repository Base Version Checkout"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        sleep 0.1
                        cd "${CUR_APP_SRC_CLONE_DIR}"
                        git reset --hard
                        git clean -fdx
                        git checkout "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        if [ $? -ne 0 ]; then
                            echo ""
                            echo "[${jj}]: Error, failed to checkout repository base version22"
                            echo "Repository name: ${BINFO_APP_NAME}"
                            echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                            echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                            echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                            echo ""
                            return 2
                        else
                            echo ""
                            echo "[${jj}]: Checked out repository base version"
                            echo "Repository name: ${BINFO_APP_NAME}"
                            echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                            echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                            echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                            echo ""
                            func_is_current_dir_a_git_submodule_dir #From build/git_utils.sh
                            cur_res=$?
                            if [ ${cur_res} == "1" ]; then
                                git submodule foreach git reset --hard
                                git submodule foreach git clean -fdx
                                git submodule deinit --all
                                git submodule update --init --recursive
                            fi
                        fi
                    else
                        echo "No need to checkout: ${BINFO_APP_NAME}, URL not defined"
                    fi
		else
                    # if this is a new repository do only the checkout without applying patches
                   func_babs_init_and_fetch_by_binfo $1 ${jj} 1
                fi
            else
                echo "Error, source directory for fetching the repository is not specified"
            fi
        else
            echo "Failed to checkout, could not find binfo file: ${APP_INFO_FULL_NAME}"
        fi
    else
        echo "Failed to checkout, binfo file not defined"
        ret_val=3
    fi
    return ${ret_val}
}

func_babs_checkout_by_binfo() {
    local jj

    if [[ -n "$1" ]]; then
        if [[ -n "$2" ]]; then
            jj=$2
        else
            jj=1
        fi
        func_babs_checkout_by_binfo_once "$1" $jj
        cur_res=$?
        if [ ${cur_res} != "0" ]; then
            # if the checkout fails, try to fetch newer source code
            # and then try to checkout again one time
            cd ${SDK_ROOT_DIR}
            func_babs_init_and_fetch_by_binfo "$1" $jj 1
            cd ${SDK_ROOT_DIR}
            func_babs_checkout_by_binfo_once "$1" $jj
            cur_res=$?
            if [ ${cur_res} != "0" ]; then
                echo ""
                echo "Failed to checkout even after fetching latest sources. ${cur_res}"
                echo "Invalid checkout tag on binfo file:"
                echo "    $1"
                echo ""
                exit 1
            fi
        fi
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
            unset BINFO_APP_SRC_CLONE_DIR
            unset BINFO_APP_UPSTREAM_REPO_URL
            BINFO_APP_UPSTREAM_REPO_VERSION_TAG=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}

            source ${APP_INFO_FULL_NAME}

            local CUR_APP_SRC_CLONE_DIR
            if [[ -n "${BINFO_APP_SRC_CLONE_DIR}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_CLONE_DIR}"
            elif [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
                CUR_APP_SRC_CLONE_DIR="${BINFO_APP_SRC_DIR}"
            else
                echo "Error: BINFO_APP_SRC_DIR not defined in ${APP_INFO_FULL_NAME}"
                exit 1
            fi

            if [ "x${CUR_APP_SRC_CLONE_DIR}" != "x" ]; then
                if [ -d ${CUR_APP_SRC_CLONE_DIR} ]; then
                    cd "${CUR_APP_SRC_CLONE_DIR}"
                    if [ -f .gitmodules ]; then
                        echo ""
                        echo "[${jj}]: Repository Submodule Update"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                        echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                        sleep 0.3
                        git submodule foreach git reset --hard
                        git submodule foreach git clean -fdx
                        git submodule update --recursive
                        git submodule foreach git fetch
                        if [ $? -ne 0 ]; then
                            echo ""
                            echo "[${jj}]: Error, failed to update repository submodules"
                            echo "Repository name: ${BINFO_APP_NAME}"
                            echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                            echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
                            echo "VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
                            echo ""
                            exit 1
                        fi
                    else
                        echo ""
                        echo "[${jj}]: No Repository Submodules to Update"
                        echo "Repository name: ${BINFO_APP_NAME}"
                        echo "Repository URL: ${BINFO_APP_UPSTREAM_REPO_URL}"
                        echo "Source directory: ${CUR_APP_SRC_CLONE_DIR}"
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

func_babs_checkout_by_blist() {
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
                   func_babs_checkout_by_binfo ${FNAME} ${ii}
               fi
            fi
        done
    else
        echo ""
        echo "Failed to checkout repositories by using the blist file."
        echo "Could not find binfo files listed in:"
        echo "    $1"
        echo ""
        exit 1
    fi
}

func_babs_apply_patches_by_blist() {
    declare -A DICTIONARY_PATCHED_PROJECTS
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
                   source ${FNAME}
                   if [ -z "${DICTIONARY_PATCHED_PROJECTS[${BINFO_APP_NAME}]}" ]; then
                       func_babs_apply_patches_by_binfo ${FNAME} ${ii}
                       DICTIONARY_PATCHED_PROJECTS[${BINFO_APP_NAME}]=1
                   else
                       echo "Patches already applied for ${BINFO_APP_NAME}"
                   fi
               fi
            fi
        done
    else
        echo ""
        echo "Failed to apply patches to repositories by using the blist file."
        echo "Could not find binfo files listed in:"
        echo "    $1"
        echo ""
        exit 1
    fi
}

func_babs_init_and_fetch_by_blist() {
    local ii
    local BINFO_ARRAY
    local skip_patches

    ii=0
    skip_patches=0
    if [[ -n "$1" ]]; then
        skip_patches=$1
    fi
    readarray -t BINFO_ARRAY < $1
    if [[ ${BINFO_ARRAY[@]} ]]; then
        local FNAME
        for FNAME in "${BINFO_ARRAY[@]}"; do
            if [ ! -z ${FNAME} ]; then
               if  [ -z ${FNAME##*.binfo} ]; then
                   ii=$(( ${ii} + 1 ))
                   cd ${SDK_ROOT_DIR}
                   func_babs_init_and_fetch_by_binfo ${FNAME} ${ii} ${skip_patches}
               fi
            fi
        done
    else
        echo ""
        echo "Failed to fetch repositories by using the blist file."
        echo "Could not find binfo files listed in:"
        echo "    $1"
        echo ""
        exit 1
    fi
}
