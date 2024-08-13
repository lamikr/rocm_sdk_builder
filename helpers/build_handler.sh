#!/bin/bash
source helpers/system_utils.sh
source helpers/config.sh

func_babs_handle_build() {
    func_env_variables_print #From config.sh
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