#!/bin/bash

#
# Copyright (c) 2024 by Mika Laitio <lamikr@gmail.com>
#
# License: GNU Lesser General Public License (LGPL), version 2.1 or later.
# See the lgpl.txt file in the root directory or <http://www.gnu.org/licenses/lgpl-2.1.html>.
#

source binfo/user_config.sh

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

func_install_dir_init() {
    local ret_val=0

    if [ -z "$INSTALL_DIR_PREFIX_SDK_ROOT" ]; then
        echo "Error: Environment variable not defined: INSTALL_DIR_PREFIX_SDK_ROOT"
        ret_val=1
    else
        if [ -d "$INSTALL_DIR_PREFIX_SDK_ROOT" ]; then
            if [ ! -w "$INSTALL_DIR_PREFIX_SDK_ROOT" ]; then
                echo "Warning: Install directory $INSTALL_DIR_PREFIX_SDK_ROOT is not writable for the user $USER"
                sudo chown "$USER:$USER" "$INSTALL_DIR_PREFIX_SDK_ROOT"
                if [ ! -w "$INSTALL_DIR_PREFIX_SDK_ROOT" ]; then
                    echo "Recommend using command: sudo chown ${USER}:${USER} $INSTALL_DIR_PREFIX_SDK_ROOT"
                    ret_val=1
                fi
            fi
        else
            echo "Trying to create install target direcory: ${INSTALL_DIR_PREFIX_SDK_ROOT}"
            mkdir -p ${INSTALL_DIR_PREFIX_SDK_ROOT} 2> /dev/null
            if [ ! -d ${INSTALL_DIR_PREFIX_SDK_ROOT} ]; then
                sudo mkdir -p ${INSTALL_DIR_PREFIX_SDK_ROOT}
                if [ -d ${INSTALL_DIR_PREFIX_SDK_ROOT} ]; then
                    echo "Install target directory created: 'sudo mkdir -p ${INSTALL_DIR_PREFIX_SDK_ROOT}'"
                    sudo chown $USER:$USER ${INSTALL_DIR_PREFIX_SDK_ROOT}
                    echo "Install target directory owner changed: 'sudo chown $USER:$USER ${INSTALL_DIR_PREFIX_SDK_ROOT}'"
                    sleep 10
                    ret_val=0
                else
                    echo "Failed to create install target directory: ${INSTALL_DIR_PREFIX_SDK_ROOT}"
                    ret_val=1
                fi
            else
                echo "Install target directory created: mkdir -p $INSTALL_DIR_PREFIX_SDK_ROOT"
                sleep 10
            fi
        fi
    fi

    return $ret_val
}

func_is_current_dir_a_git_repo_dir() {
    local inside_git_repo
    inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

    if [ "$inside_git_repo" ]; then
        return 0  # is a git repo
    else
        return 1  # not a git repo
    fi
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
    local jj=0

    # Display a message if src_projects directory does not exist
    if [ ! -d src_projects ]; then
        printf "\n"
        cat <<EOF
Download of source projects will start shortly.
It will take up about 20 GB under 'src_projects' directory.
Advice:
If you work with multiple copies of this SDK,
you could tar 'src_projects' and extract it manually for other SDK copies.

EOF
        sleep 3
    fi

    # Initialize git repositories and add upstream remote
    while [ -n "${LIST_APP_SRC_CLONE_DIR[jj]}" ]; do
        if [ ! -d "${LIST_APP_SRC_CLONE_DIR[jj]}" ]; then
            echo "${jj}: Creating source code directory: ${LIST_APP_SRC_CLONE_DIR[jj]}"
            sleep 0.2
            mkdir -p "${LIST_APP_SRC_CLONE_DIR[jj]}"
            # LIST_APP_ADDED_UPSTREAM_REPO parameter is used in
            # situations where same src_code directory is used for building multiple projects
            # with just different configure parameters (for example amd-fftw)
            # in this case we want to add upstream repo and apply patches only once
            LIST_APP_ADDED_UPSTREAM_REPO[jj]=1
        fi

        if [[ "${LIST_APP_UPSTREAM_REPO_DEFINED[jj]}" == "1" ]]; then
            if [ ! -d "${LIST_APP_SRC_CLONE_DIR[jj]}/.git" ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
                echo "${jj}: Initializing new source code repository"
                echo "Repository URL[$jj]: ${LIST_APP_UPSTREAM_REPO_URL[jj]}"
                echo "Source directory[$jj]: ${LIST_APP_SRC_CLONE_DIR[jj]}"
                echo "VERSION_TAG[$jj]: ${LIST_APP_UPSTREAM_REPO_VERSION_TAG[jj]}"
                sleep 0.5
                git init
                echo "${LIST_APP_UPSTREAM_REPO_URL[jj]}"
                git remote add upstream "${LIST_APP_UPSTREAM_REPO_URL[jj]}"
                LIST_APP_ADDED_UPSTREAM_REPO[jj]=1
                echo -e "\n"
            else
                LIST_APP_ADDED_UPSTREAM_REPO[jj]=0
                echo "${jj}: ${LIST_APP_SRC_CLONE_DIR[jj]} ok"
                echo -e "\n"
            fi
        else
            LIST_APP_ADDED_UPSTREAM_REPO[jj]=0
            echo "${jj}: ${LIST_APP_SRC_CLONE_DIR[jj]} ok"
        fi
        ((jj++))
        sleep 0.2
    done

    # Fetch updates and initialize submodules
    jj=0
    while [ -n "${LIST_APP_SRC_CLONE_DIR[jj]}" ]; do
        # check if directory was just created and git fetch needs to be done
        if [[ "${LIST_APP_ADDED_UPSTREAM_REPO[jj]}" -eq 1 ]]; then
            echo "${jj}: git fetch on ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
            git fetch upstream
            if [ $? -ne 0 ]; then
                echo "git fetch failed: ${LIST_APP_SRC_CLONE_DIR[jj]}"
                #exit 1
            fi
            git fetch upstream --force --tags
            git checkout "${LIST_APP_UPSTREAM_REPO_VERSION_TAG[jj]}"
            func_is_current_dir_a_git_submodule_dir
            ret_val=$?
            if [ ${ret_val} == "1" ]; then
                echo "submodule init and update"
                git submodule update --init --recursive
                if [ $? -ne 0 ]; then
                    echo "git submodule init and update failed: ${LIST_APP_SRC_CLONE_DIR[jj]}"
                    exit 1
                fi
            fi
        fi
        ((jj++))
    done

    # Apply patches if patch directory exists
    jj=0
    while [ -n "${LIST_APP_PATCH_DIR[jj]}" ]; do
        # check if directory was just created and git am needs to be done
        if [ ${LIST_APP_ADDED_UPSTREAM_REPO[jj]} -eq 1 ]; then
            TEMP_PATCH_DIR=${LIST_APP_PATCH_DIR[jj]}
            cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
            echo "patch dir: ${TEMP_PATCH_DIR}"
            if [ -d "${TEMP_PATCH_DIR}" ]; then
                if [ -n "$(ls -A "$TEMP_PATCH_DIR")" ]; then
                    echo "git am: ${LIST_BINFO_APP_NAME[jj]}"
                    git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
                    if [ $? -ne 0 ]; then
                        git am --abort
                        echo ""
                        echo "Failed to apply patches for repository"
                        echo "${LIST_APP_SRC_CLONE_DIR[jj]}"
                        echo "git am ${TEMP_PATCH_DIR}/*.patch failed"
                        echo ""
                        exit 1
                    else
                        echo "patches applied: ${LIST_APP_SRC_CLONE_DIR[jj]}"
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
        fi
        ((jj++))
    done
}

func_repolist_fetch_top_repo() {
    echo "func_repolist_fetch_top_repo started"

    local jj=0

    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[jj]}" == "1" ]; then
            if [ -d "${LIST_APP_SRC_CLONE_DIR[jj]}" ]; then
                cd "${LIST_APP_SRC_CLONE_DIR[jj]}"

                echo "Repository name: ${LIST_BINFO_APP_NAME[jj]}"
                echo "Repository URL[$jj]: ${LIST_APP_UPSTREAM_REPO_URL[jj]}"
                echo "Source directory[$jj]: ${LIST_APP_SRC_CLONE_DIR[jj]}"

                git fetch upstream

                if [ $? -ne 0 ]; then
                    echo "git fetch failed: ${LIST_APP_SRC_CLONE_DIR[jj]}"
                    exit 1
                fi
                git fetch upstream --force --tags
            else
                echo ""
                echo "Failed to fetch source code for repository ${LIST_BINFO_APP_NAME[jj]}"
                echo "Source directory[$jj] not initialized with '-i' command:"
                echo "    ${LIST_APP_SRC_CLONE_DIR[jj]}"
                echo "Repository URL[$jj]: ${LIST_APP_UPSTREAM_REPO_URL[jj]}"
                echo ""
                exit 1
            fi
        else
            echo "No repository defined for project in directory: ${LIST_APP_SRC_CLONE_DIR[jj]}"
        fi
        ((jj++))
    done
}

func_repolist_fetch_submodules() {
    echo "func_repolist_fetch_submodules started"

    local jj=0

    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
        cd "${LIST_APP_SRC_CLONE_DIR[jj]}"

        if [ -f .gitmodules ]; then
            echo "submodule update"
            git submodule foreach git reset --hard
            git submodule update --recursive

            if [ $? -ne 0 ]; then
                echo "git submodule update failed: ${LIST_APP_SRC_CLONE_DIR[jj]}"
                exit 1
            fi
        fi
        ((jj++))
    done
}

func_repolist_checkout_default_versions() {
    echo "func_repolist_checkout_default_versions started"
    local jj=0

    while [ "x${LIST_APP_PATCH_DIR[jj]}" != "x" ]; do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[jj]}" == "1" ]; then
            echo "[$jj]: Repository to reset: ${LIST_BINFO_APP_NAME[jj]}"
            sleep 0.2
            cd "${LIST_APP_SRC_CLONE_DIR[jj]}"
            git reset --hard
            git checkout "${LIST_APP_UPSTREAM_REPO_VERSION_TAG[jj]}"
        fi
        ((jj++))
    done
}

# Function to check that repositories do not have uncommitted patches, changes that differ from original patches,
# or are not in a state where 'git am' apply has failed.
func_repolist_is_changes_committed() {
    echo "func_repolist_is_changes_committed started"
    local jj=0

    while [[ -n "${LIST_APP_PATCH_DIR[jj]}" ]]; do
        if [[ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]]; then
            repo_dir="${LIST_APP_SRC_CLONE_DIR[$jj]}"

            if [[ -d "$repo_dir" ]]; then
                cd "$repo_dir"
                func_is_current_dir_a_git_repo_dir

                if [[ $? -eq 0 ]]; then
                    if [[ -n $(git status --porcelain --ignore-submodules=all) ]]; then
                        echo "Uncommitted changes in: $repo_dir"
                        exit 1
                    fi

                    if git status | grep -q "git am --skip"; then
                        echo "Unresolved 'git am' in: $repo_dir"
                        exit 1
                    else
                        echo "Repository clean: $repo_dir"
                    fi
                else
                    echo "Not a git repository: $repo_dir"
                fi
            else
                echo "Directory does not exist: $repo_dir"
            fi
        fi
        ((jj++))
    done
}

func_repolist_appliad_patches_save() {
    local jj=0
    cmd_diff_check=(git diff --exit-code)
    DATE=$(date "+%Y%m%d")
    DATE_WITH_TIME=$(date "+%Y%m%d-%H%M%S")
    PATCHES_DIR="$(pwd)/patches/${DATE_WITH_TIME}"

    echo "${PATCHES_DIR}"
    mkdir -p "${PATCHES_DIR}"

    while [[ -n "${LIST_APP_SRC_CLONE_DIR[jj]}" ]]; do
        if [[ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]]; then
            repo_dir="${LIST_APP_SRC_CLONE_DIR[jj]}"

            if [[ -d "$repo_dir" ]]; then
                cd "$repo_dir"
                func_is_current_dir_a_git_repo_dir

                if [[ $? -eq 0 ]]; then
                    "${cmd_diff_check[@]}" &>/dev/null
                    if [[ $? -ne 0 ]]; then
                        fname="$(basename -- "$repo_dir").patch"
                        echo "diff: ${DATE_WITH_TIME}/${fname}"
                        "${cmd_diff_check[@]}" >"${PATCHES_DIR}/${fname}"
                    fi
                else
                    echo "Not a git repository: $repo_dir"
                fi
            else
                echo "Directory does not exist: $repo_dir"
            fi
        fi
        ((jj++))
    done

    echo "Patches generated: ${PATCHES_DIR}"
}

func_repolist_export_version_tags_to_file() {
    local jj=0

    while [[ -n "${LIST_APP_SRC_CLONE_DIR[jj]}" ]]; do
        if [[ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]]; then
            local repo_dir="${LIST_APP_SRC_CLONE_DIR[jj]}"
            local app_name="${LIST_BINFO_APP_NAME[jj]}"

            if [[ -d "$repo_dir" ]]; then
                cd "$repo_dir"
                func_is_current_dir_a_git_repo_dir

                if [[ $? -eq 0 ]]; then
                    local githash
                    githash=$(git rev-parse --short=8 HEAD 2>/dev/null)

                    if [[ $jj -eq 0 ]]; then
                        echo "${githash} ${app_name}" > "${FNAME_REPO_REVS_NEW}"
                    else
                        echo "${githash} ${app_name}" >> "${FNAME_REPO_REVS_NEW}"
                    fi
                else
                    echo "Not a git repository: $repo_dir"
                fi
            else
                echo "Directory does not exist: $repo_dir"
            fi
        fi
        ((jj++))
    done

    echo "Repository hash list generated: ${FNAME_REPO_REVS_NEW}"
}

func_repolist_find_app_index_by_app_name() {
    local temp_search_name="$1"
    local kk=0

    RET_INDEX_BY_NAME=-1

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

    REPO_UPSTREAM_NAME=${1:-"--all"}
    for (( jj=0; jj<${#LIST_APP_SRC_CLONE_DIR[@]}; jj++ )); do
        if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]; then
            echo "repo dir: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}" || { echo "Not a git repository: ${LIST_APP_SRC_CLONE_DIR[jj]}"; exit 1; }
            func_is_current_dir_a_git_repo_dir || { echo "Not a git repository: ${LIST_APP_SRC_CLONE_DIR[jj]}"; exit 1; }
            echo "${LIST_BINFO_APP_NAME[jj]}: git fetch ${REPO_UPSTREAM_NAME}"
            git fetch ${REPO_UPSTREAM_NAME} || { echo "git fetch ${REPO_UPSTREAM_NAME} failed: ${LIST_BINFO_APP_NAME[jj]}"; }
            [ -f .gitmodules ] && git submodule update --recursive
            sleep 1
        else
            echo "Upstream fetch all skipped, no repository defined: ${LIST_BINFO_APP_NAME[$jj]}"
        fi
    done
}

func_repolist_version_tag_read_to_array_list_from_file() {
    echo "func_repolist_version_tag_read_to_array_list_from_file"

    declare -a LIST_REPO_REVS_CUR=()
    declare -a LIST_TEMP=()
    readarray -t LIST_TEMP < "$FNAME_REPO_REVS_CUR"
    echo "reading: $FNAME_REPO_REVS_CUR"

    for (( jj=0; jj<${#LIST_TEMP[@]}; jj+=2 )); do
        TEMP_HASH=${LIST_TEMP[jj]}
        TEMP_NAME=${LIST_TEMP[jj+1]}

        func_repolist_find_app_index_by_app_name "$TEMP_NAME"
        if [ $RET_INDEX_BY_NAME -ge 0 ]; then
            LIST_REPO_REVS_CUR[$RET_INDEX_BY_NAME]=$TEMP_HASH
            if [ "${LIST_APP_UPSTREAM_REPO_DEFINED[$RET_INDEX_BY_NAME]}" == "1" ]; then
                echo "find_index_by_name $TEMP_NAME: ${LIST_REPO_REVS_CUR[$RET_INDEX_BY_NAME]}, repo: ${LIST_APP_UPSTREAM_REPO_URL[$RET_INDEX_BY_NAME]}"
            fi
        else
            echo "Find_index_by_name failed for name: $TEMP_NAME"
            exit 1
        fi
    done
}

func_repolist_checkout_by_version_tag_file() {
    echo "func_repolist_checkout_by_version_tag_file"
    func_repolist_fetch_by_version_tag_file

    # Read hashes from the stored txt file
    func_repolist_version_tag_read_to_array_list_from_file

    for (( jj=0; jj<${#LIST_APP_SRC_CLONE_DIR[@]}; jj++ )); do
        if [[ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}" || { echo "Failed to cd into ${LIST_APP_SRC_CLONE_DIR[$jj]}"; exit 1; }

            if func_is_current_dir_a_git_repo_dir; then
                echo "git checkout: ${LIST_BINFO_APP_NAME[$jj]}"
                if git checkout "${LIST_REPO_REVS_CUR[$jj]}"; then
                    echo "Repository checkout ok: ${LIST_BINFO_APP_NAME[$jj]}"
                    echo "    revision: ${LIST_REPO_REVS_CUR[$jj]}"
                else
                    echo "Repository checkout failed: ${LIST_BINFO_APP_NAME[$jj]}"
                    echo "    Revision: ${LIST_REPO_REVS_CUR[$jj]}"
                    exit 1
                fi
            else
                echo "Not a git repository: ${LIST_APP_SRC_CLONE_DIR[$jj]}"
            fi
        else
            echo "Upstream repository checkout skipped, no repository defined: ${LIST_BINFO_APP_NAME[$jj]}"
        fi
    done
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
							echo "[$jj]: ${LIST_BINFO_APP_NAME[${jj}]}: applying patches"
							sleep 0.2
							git am --keep-cr "${TEMP_PATCH_DIR}"/*.patch
							if [ $? -ne 0 ]; then
								git am --abort
								echo ""
								echo "repository: ${LIST_APP_SRC_CLONE_DIR[${jj}]}"
								echo "git am ${TEMP_PATCH_DIR[jj]}/*.patch failed"
								echo ""
								exit 1
							else
								echo "patches applied: ${LIST_APP_SRC_CLONE_DIR[${jj}]}"
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
					sleep 0.2
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
}

func_repolist_checkout_by_version_param() {
    if [[ -z $1 ]]; then
        echo "Error: git version parameter missing"
        exit 1
    fi

    CHECKOUT_VERSION=$1
    echo "func_repolist_checkout_by_version_param: ${CHECKOUT_VERSION}"

    for (( jj=0; jj<${#LIST_APP_SRC_CLONE_DIR[@]}; jj++ )); do
        if [[ "${LIST_APP_UPSTREAM_REPO_DEFINED[$jj]}" == "1" ]]; then
            cd "${LIST_APP_SRC_CLONE_DIR[$jj]}" || { echo "Failed to cd into ${LIST_APP_SRC_CLONE_DIR[$jj]}"; exit 1; }

            if func_is_current_dir_a_git_repo_dir; then
                if git checkout "${CHECKOUT_VERSION}"; then
                    echo "Repo checkout successful: ${LIST_BINFO_APP_NAME[jj]}"
                    echo "   Version: ${CHECKOUT_VERSION}"
                else
                    echo "Git checkout failed: ${LIST_BINFO_APP_NAME[jj]}"
                    echo "   Version: ${CHECKOUT_VERSION}"
                fi
            else
                echo "Not a git repo: ${LIST_APP_SRC_CLONE_DIR[jj]}"
            fi
        else
            echo "Upstream repo checkout skipped, no repository defined: ${LIST_BINFO_APP_NAME[$jj]}"
        fi
    done
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
    local vars=(
        "SDK_CXX_COMPILER_DEFAULT" "HIP_PLATFORM_DEFAULT" "HIP_PLATFORM" "HIP_PATH"
        "SDK_ROOT_DIR" "SDK_SRC_ROOT_DIR" "BUILD_RULE_ROOT_DIR" "PATCH_FILE_ROOT_DIR"
        "BUILD_ROOT_DIR" "INSTALL_DIR_PREFIX_SDK_ROOT" "INSTALL_DIR_PREFIX_HIPCC"
        "INSTALL_DIR_PREFIX_HIP_CLANG" "INSTALL_DIR_PREFIX_C_COMPILER" "INSTALL_DIR_PREFIX_HIP_LLVM"
        "SPACE_SEPARATED_GPU_TARGET_LIST_DEFAULT" "SEMICOLON_SEPARATED_GPU_TARGET_LIST_DEFAULT"
        "LF_SEPARATED_GPU_TARGET_LIST_DEFAULT" "HIP_PATH_DEFAULT"
    )

    for var in "${vars[@]}"; do
        echo "${var}: ${!var}"
    done
}

func_build_system_name_and_version_print() {
    echo "babs version: ${BABS_VERSION:-unknown}"
    echo "sdk version: ${ROCM_SDK_VERSION_INFO:-unknown}"
}


func_user_help_print() {
    func_build_system_name_and_version_print

    cat << EOF
babs (babs ain't patch build system)
usage:
-h or --help:           Show this help
-c or --configure:      Show list of GPU's for which the build is optimized
-i or --init:           Download git repositories listed in binfo directory to 'src_projects' directory
                        and apply all patches from 'patches' directory.
-ap or --apply_patches: Scan 'patches/rocm-version' directory and apply each patch
                        on top of the repositories in 'src_projects' directory.
-co or --checkout:      Checkout version listed in binfo files for each git repository in 'src_projects' directory.
                        Apply patches on top of the checked out version separately with '-ap' command.
-f or --fetch:          Fetch latest source code for all repositories.
                        Checkout of fetched sources needs to be performed separately with '-co' command.
                        Fetch subprojects separately with '-fs' command (after '-co' and '-ap').
-fs or --fetch_submod:  Fetch and checkout git submodules for all repositories which have them.
-b or --build:          Start or continue building rocm_sdk.
                        Build files are located under 'builddir' directory and install is done under '/opt/rocm_sdk_version' directory.
-v or --version:        Show babs build system version information
EOF

    # Uncomment if these commands need to be included
    # -cp or --create_patches: Generate patches by checking git diff for each repository.
    # -g or --generate_repo_list: Generates repo_list_new.txt file containing current repository revision hash for each project.
    # -s or --sync: Checkout all repositories to base git hash.

    if [[ ! -d src_projects ]]; then
        cat << EOF

----------------Advice ---------------
No ROCm project source codes detected in 'src_projects' directory.
I recommend downloading them first with command './babs.sh -i'

Projects will be loaded to 'src_projects' directory
and will require about 20GB of space.
If download of some projects fails, you can issue './babs.sh -i' command again.
--------------------------------------

EOF
    elif [[ ! -d builddir ]]; then
        cat << EOF

----------------Advice ---------------
No ROCm 'builddir' directory detected.
Once projects source code has been downloaded with './babs.sh -i' command,
you can start building with command './babs.sh -b'.
--------------------------------------

EOF
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
            echo -e "\nYou need to configure git user's email address. Example command:"
            echo "    git config --global user.email \"john.doe@emailserver.com\""
            echo ""
            exit 2
        fi
    else
        echo -e "\nYou need to configure git user's name and email address. Example commands:"
        echo "    git config --global user.name \"John Doe\""
        echo "    git config --global user.email \"john.doe@emailserver.com\""
        echo ""
        exit 2
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

    while [[ -n "${LIST_USER_CMD_ARGS[ii]}" ]]; do
        case "${LIST_USER_CMD_ARGS[ii]}" in
            -ap|--apply_patches)
                func_is_git_configured
                func_repolist_apply_patches
                echo "Patches applied to git repositories"
                exit 0
                ;;
            -b|--build)
                func_env_variables_print
                func_install_dir_init
                local ret_val=$?
                if [[ $ret_val -eq 0 ]]; then
                    ./build/build.sh
                    local res=$?
                    if [[ $res -eq 0 ]]; then
                        echo -e "\nROCM SDK build and install ready"
                        echo "You can use the following commands to test your gpu is detected:"
			echo ""
                        echo "    source ${INSTALL_DIR_PREFIX_SDK_ROOT}/bin/env_rocm.sh"
                        echo "    rocminfo"
			echo ""
			echo "If probelms, check read and write permissions of /dev/kfd AMD gpu device driver"
			echo ""
                    else
                        echo -e "Build failed"
                    fi
                    exit 0
                else
                    echo "Failed to initialize install directory"
                    exit 1
                fi
                ;;
            -cp|--create_patches)
                func_repolist_appliad_patches_save
                exit 0
                ;;
            -co|--checkout)
                func_repolist_checkout_default_versions
                exit 0
                ;;
            -f|--fetch)
                func_repolist_fetch_top_repo
                exit 0
                ;;
            -fs|--fetch_submod)
                func_repolist_fetch_submodules
                exit 0
                ;;
            -g|--generate_repo_list)
                func_repolist_export_version_tags_to_file
                exit 0
                ;;
            -i|--init)
                func_is_git_configured
                func_repolist_upstream_remote_repo_add
                echo "All git repositories initialized"
                exit 0
                ;;
            -s|--sync)
                func_repolist_checkout_by_version_tag_file
                exit 0
                ;;
            *)
                echo "Unknown user command parameter: ${LIST_USER_CMD_ARGS[ii]}"
                exit 1
                ;;
        esac
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
