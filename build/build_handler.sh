#!/bin/bash
source build/system_utils.sh
source build/config.sh
source build/build_func.sh

func_babs_handle_build() {
    func_env_variables_print #From config.sh
    func_install_dir_init ${INSTALL_DIR_PREFIX_SDK_AI_MODELS}
    func_install_dir_init ${INSTALL_DIR_PREFIX_SDK_ROOT}
    local ret_val=$?
    if [[ $ret_val -eq 0 ]]; then
        if [[ -n "$1" ]]; then
            source ./build/build_func.sh
            if [[ "$1" = *.binfo ]] ; then
                func_init_and_build_single_binfo $1
            fi
            if [[ "$1" = *.blist ]] ; then
                func_init_and_build_blist $1
            fi
        else
            source ./build/build_core.sh
        fi
        res=$?
        if [[ $res -eq 0 ]]; then
            echo -e "\nROCM SDK build and install ready"
            func_is_user_in_dev_kfd_render_group #From system_utils.sh
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

func_babs_handle_checkout() {
    if [[ -n "$1" ]]; then
        echo "func_babs_handle_checkout param: $1"
        if [[ "$1" = *.binfo ]] ; then
            func_envsetup_init
            func_babs_checkout_by_binfo $1
        fi
        if [[ "$1" = *.blist ]] ; then
            func_envsetup_init
            func_babs_checkout_by_blist $1
        fi
    else
        echo "func_babs_handle_checkout no params"
        func_repolist_checkout_default_versions
    fi
}

func_babs_handle_apply_patches() {
    if [[ -n "$1" ]]; then
        echo "func_babs_handle_patch_apply param: $1"
        if [[ "$1" = *.binfo ]] ; then
            func_envsetup_init
            func_babs_apply_patches_by_binfo ${ARG__USER_CMD_PARAM1} #From build/binfo_operations.sh
        fi
        if [[ "$1" = *.blist ]] ; then
            func_envsetup_init
            func_babs_apply_patches_by_blist ${ARG__USER_CMD_PARAM1} #From build/binfo_operations.sh
        fi
    else
        echo "func_babs_handle_patch_apply no params"
        func_repolist_apply_patches build/binfo_operations.sh
    fi
}

func_babs_handle_checkout_and_apply_patches() {
    if [[ -n "$1" ]]; then
        echo "func_babs_handle_checkout_and_apply_patches param: $1"
        if [[ "$1" = *.binfo ]] ; then
            func_envsetup_init
            func_babs_checkout_by_binfo ${ARG__USER_CMD_PARAM1}
            func_babs_apply_patches_by_binfo ${ARG__USER_CMD_PARAM1}
        fi
        if [[ "$1" = *.blist ]] ; then
            func_envsetup_init
            func_babs_checkout_by_blist ${ARG__USER_CMD_PARAM1}
            func_babs_apply_patches_by_blist ${ARG__USER_CMD_PARAM1}
        fi
    else
        func_repolist_checkout_default_versions
        func_repolist_apply_patches build/binfo_operations.sh
    fi
}

func_babs_handle_repository_fetch() {
    if [[ -n "$1" ]]; then
        echo "func_babs_handle_fetch param: $1"
        if [[ "$1" = *.binfo ]] ; then
            func_envsetup_init
            # if new repo is created, apply also patches
            func_babs_init_and_fetch_by_binfo ${ARG__USER_CMD_PARAM1} 0
        fi
        if [[ "$1" = *.blist ]] ; then
            func_envsetup_init
            # if new repo is created, apply also patches
            func_babs_init_and_fetch_by_blist ${ARG__USER_CMD_PARAM1} 0
        fi
    else
        # if new repo is created, apply also patches
        func_repolist_init_and_fetch_core_repositories 0
    fi
}

# todo: Check whether these functions used here can be replaced with the ones
# on func_babs_handle_repository_fetch
# because the functionality in these functions is now most likely exactly similar
# than in the fetch functions. Fetch functions has been updated to
# handle the checkout, apply patches and submodules also if the repositories does not exist.
func_babs_handle_repository_init() {
    if [[ -n "$1" ]]; then
        echo "func_babs_handle_init param: $1"
        if [[ "$1" = *.binfo ]] ; then
            func_envsetup_init
            func_upstream_remote_repo_add_by_binfo ${ARG__USER_CMD_PARAM1}
        fi
        if [[ "$1" = *.blist ]] ; then
            func_envsetup_init
            func_upstream_remote_repo_add_by_blist ${ARG__USER_CMD_PARAM1}
        fi
    else
        func_repolist_upstream_remote_repo_add #From build/repo_management.sh
    fi
}
