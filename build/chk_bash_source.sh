#!/bin/bash
#
# This script needs to be sourced

check_bash_sourced() {
	if [ ${0:0:4} != bash ] && [ ${0:0:4} != -bas ];
	then
		echo "Script execution failed, script must be called as sourced!"
        	echo "source $0"
		exit 1;
	fi
}
