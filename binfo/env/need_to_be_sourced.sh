#!/bin/bash

# This script needs to be sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Script execution failed. Please use the following command to source the script:"
    echo "    source $0"
    echo ""
    exit 1
fi

