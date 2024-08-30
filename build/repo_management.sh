#!/bin/bash
source build/git_utils.sh
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
        echo "Total download size under 'src_projects' directory will be about 30 GB."
        echo ""
        echo "----------------------------------------------------------------"
        echo "You could speedup future builds by using a backup of src_projects directory:"
        echo "Backup:"
        echo "    tar -cvf src_backup.tar 'src_projects'"
        echo "Restore:"
        echo "    cd rocm_sdk_builder_dir2"
        echo "    tar -xvf src_backup.tar"
        echo "----------------------------------------------------------------"
        echo ""
        sleep 3
    fi
    # Initialize git repositories and add upstream remote
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]; do
        if [ ! -d ${LIST_APP_SRC_CLONE_DIR[$jj]} ]; then
            echo ""
            echo "[${jj}]: Creating repository source code directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
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
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]; do
        # echo "LIST_APP_ADDED_UPSTREAM_REPO[$jj]: ${LIST_APP_ADDED_UPSTREAM_REPO[$jj]}"
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
            func_is_current_dir_a_git_submodule_dir #From build/git_utils.sh
            cur_res=$?
            if [ ${cur_res} == "1" ]; then
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
    # apply patches if patch directory exist
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
        # echo "LIST_APP_ADDED_UPSTREAM_REPO[$jj]: ${LIST_APP_ADDED_UPSTREAM_REPO[$jj]}"
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
                    echo "[${jj}]: Warning, patch directory exist but is empty: ${TEMP_PATCH_DIR}"
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

func_repolist_init_and_fetch_core_repositories() {
    local jj
    local skip_patches

    jj=0
    if [[ -n "$1" ]]; then
        skip_patches=$1
    fi
    echo "func_repolist_init_and_fetch_core_repositories started"
    while [ "x${LIST_APP_UPSTREAM_REPO_DEFINED[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            echo "LIST_BINFO_FILE_FULLNAME: ${LIST_BINFO_FILE_FULLNAME[$jj]}"
            pwd
            func_babs_init_and_fetch_by_binfo ${LIST_BINFO_FILE_FULLNAME[$jj]} ${jj} ${skip_patches}
        else
            if [ ! -z ${LIST_APP_SRC_CLONE_DIR[$jj]} ]; then
                echo "Repository not defined, skipping checkout:"
                echo "LIST_BINFO_FILE_FULLNAME: ${LIST_BINFO_FILE_FULLNAME[$jj]}"
            fi
        fi
        ((jj++))
    done
    echo ""
    echo "All source code repositories fetched ok"
}

func_repolist_fetch_submodules() {
    local jj

    jj=0
    echo "func_repolist_fetch_submodules started"
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
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

func_repolist_checkout_default_versions() {
    local jj

    jj=0
    echo "func_repolist_checkout_default_versions started"
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            echo ""
            echo "[$jj]: Repository Base Version Checkout"
            echo "Repository name: ${LIST_BINFO_APP_NAME[${jj}]}"
            echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
            echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
            sleep 0.1
            if [ -d ${LIST_APP_SRC_CLONE_DIR[$jj]} ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
                git reset --hard
                git checkout "${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                if [ $? -ne 0 ]; then
                    # try to fetch source code and then try again one time
                    git fetch
                    git fetch --tags
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
                func_is_current_dir_a_git_submodule_dir #From build/git_utils.sh
                cur_res=$?
                if [ ${cur_res} == "1" ]; then
                    git submodule foreach git reset --hard
                    git submodule foreach git clean -fdx
                    git submodule deinit --all
                    git submodule update --init --recursive
                fi
            else
                # source directory does not exist, maybe a new one...
                # download it from the repository and checkout the correct version
                cd ${SDK_ROOT_DIR}
                source ./build/binfo_operations.sh
                cd binfo
                # init repository and checkout default version but do not apply patches
                func_babs_init_and_fetch_by_binfo ${LIST_BINFO_FILE_BASENAME[jj]} ${jj} 1
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
    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir #From git_utils.sh
            if [ $? -eq 0 ]; then
                if [[ $(git status --porcelain --ignore-submodules=all) ]]; then
                    echo "git status error: " ${LIST_APP_SRC_CLONE_DIR[$jj]}
                    exit 1
                else
                    # No changes
                    #echo "git status ok: " ${LIST_APP_SRC_CLONE_DIR[$jj]}
                    #if [[ `git am --show-current-patch > /dev/null ` ]]; then
                    git status | grep "git am --skip" >/dev/null
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
    DATE=$(date "+%Y%m%d")
    DATE_WITH_TIME=$(date "+%Y%m%d-%H%M%S")
    PATCHES_DIR=$(pwd)/patches/${DATE_WITH_TIME}
    echo ${PATCHES_DIR}
    mkdir -p ${PATCHES_DIR}
    if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
        cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
        func_is_current_dir_a_git_repo_dir #From git_utils.sh
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
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
            func_is_current_dir_a_git_repo_dir #From git_utils.sh
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
        func_is_current_dir_a_git_repo_dir #From git_utils.sh
        if [ $? -eq 0 ]; then
            GITHASH=$(git rev-parse --short=8 HEAD)
            echo "${GITHASH} ${LIST_BINFO_APP_NAME[${jj}]}" >${FNAME_REPO_REVS_NEW}
        else
            echo "Not a git repo: " ${LIST_APP_SRC_CLONE_DIR[jj]}
        fi
    fi
    ((jj++))
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir #From git_utils.sh
            if [ $? -eq 0 ]; then
                GITHASH=$(git rev-parse --short=8 HEAD 2>/dev/null)
                echo "${GITHASH} ${LIST_BINFO_APP_NAME[${jj}]}" >>${FNAME_REPO_REVS_NEW}
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
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            echo "repo dir: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir #From git_utils.sh
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
    LIST_TEMP=($(cat "${FNAME_REPO_REVS_CUR}"))
    echo "reading: ${FNAME_REPO_REVS_CUR}"

    jj=0
    while [ "x${LIST_TEMP[jj]}" != "x" ]; do
        TEMP_HASH=${LIST_TEMP[$jj]}
        ((jj++))
        #echo "Element [$jj]: ${LIST_TEMP[$jj]}"
        TEMP_NAME=${LIST_TEMP[$jj]}
        #echo "Element [$jj]: ${TEMP_NAME}"

        func_repolist_find_app_index_by_app_name "${TEMP_NAME}"
        if [ ${RET_INDEX_BY_NAME} -ge 0 ]; then
            LIST_REPO_REVS_CUR[$RET_INDEX_BY_NAME]=${TEMP_HASH}
            if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$RET_INDEX_BY_NAME]}" == "1" ]; then
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
    while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
            func_is_current_dir_a_git_repo_dir #From git_utils.sh
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

func_repolist_apply_patches() {
    declare -A DICTIONARY_PATCHED_PROJECTS
    echo "func_repolist_apply_patches"
    jj=0
    while [ "x${LIST_APP_SRC_CLONE_DIR[$jj]}" != "x" ]; do
        if [ -z "${DICTIONARY_PATCHED_PROJECTS[${LIST_BINFO_APP_NAME[$jj]}]}" ]; then
            if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" = "1" ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
                func_is_current_dir_a_git_repo_dir # From git_utils.sh
                if [ $? -eq 0 ]; then
                    TEMP_PATCH_DIR="${LIST_APP_PATCH_DIR[$jj]}"
                    echo "patch dir: ${TEMP_PATCH_DIR}"
                    if [ -d "${TEMP_PATCH_DIR}" ]; then
                        if [ ! -z "$(ls -A "${TEMP_PATCH_DIR}")" ]; then
                            echo ""
                            echo "[$jj]: Repository Apply Patches"
                            echo "Repository name: ${LIST_BINFO_APP_NAME[$jj]}"
                            echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                            echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                            echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                            sleep 0.1
                            git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
                            if [ $? -ne 0 ]; then
                                git am --abort
                                echo ""
                                echo "[$jj]: Error, failed to apply patches"
                                echo "Repository name: ${LIST_BINFO_APP_NAME[$jj]}"
                                echo "Repository URL: ${LIST_APP_UPSTREAM_REPO_URL[$jj]}"
                                echo "Source directory: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                                echo "VERSION_TAG: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]}"
                                echo "Patch directory: ${TEMP_PATCH_DIR}"
                                echo ""
                                exit 1
                            else
                                echo "[$jj]: Patches applied ok: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                            fi
                            DICTIONARY_PATCHED_PROJECTS[${LIST_BINFO_APP_NAME[$jj]}]=1
                        else
                            echo "Warning, empty patch directory: ${TEMP_PATCH_DIR}"
                            sleep 2
                        fi
                    else
                        echo "${LIST_BINFO_APP_NAME[$jj]}: No patches to apply"
                    fi
                    sleep 0.1
                else
                    echo "Warning, not a git repository: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
                    sleep 2
                fi
            else
                echo "repo am patches skipped, no repository defined: ${LIST_BINFO_APP_NAME[$jj]}"
            fi
        else
            echo "[$jj]: ${LIST_BINFO_APP_NAME[$jj]}: patches already applied, skipping"
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
        while [ "x${LIST_APP_SRC_CLONE_DIR[jj]}" != "x" ]; do
            if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[$jj]}"
                func_is_current_dir_a_git_repo_dir #From git_utils.sh
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
