#!/bin/bash

# This script needs to be sourced
if [ "${0:0:4}" != "bash" ] && [ "${0:0:4}" != "-bas" ]; then
    echo "Script execution failed. Please use the following command to source the script:"
    echo "    source $0"
    echo ""
    exit 1
fi

