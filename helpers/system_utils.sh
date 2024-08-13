#!/bin/bash

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
            mkdir -p ${CUR_INSTALL_DIR_PATH} 2>/dev/null
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