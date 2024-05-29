#!/bin/bash

# This script needs to be sourced

check_bash_sourced() {
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        echo "Script execution failed, script must be called as sourced!"
        echo "source ${BASH_SOURCE[0]}"
        exit 1
    fi
}