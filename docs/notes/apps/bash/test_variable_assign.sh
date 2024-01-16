BINFO_APP_BUILD_CMD1="HELLO=5"
BINFO_APP_BUILD_CMD2="HELLO=\$5"

BINFO_APP_BUILD_CMD_ARRAY[0]="HELLOJEE=5"
BINFO_APP_BUILD_CMD_ARRAY[1]="HELLOWEE=\${HELLO}"

func_assing_from_array() {
    while [ "x${BINFO_APP_BUILD_CMD_ARRAY[jj]}" != "x" ]
    do
	    #echo "${BINFO_APP_NAME}, build command  ${jj}:"
	    #echo "${BINFO_APP_BUILD_CMD_ARRAY[jj]}"
	    echo "HELLOJEE: ${HELLOJEE}"
	    echo "cmd: ${BINFO_APP_BUILD_CMD_ARRAY[${jj}]}"
        eval ${BINFO_APP_BUILD_CMD_ARRAY[${jj}]}
        res=$?
        jj=$(( ${jj} + 1 ))
    done
}

#eval "export $BINFO_APP_BUILD_CMD_ARRAY[0]"
eval ${BINFO_APP_BUILD_CMD1}
echo "HELLO: ${HELLO}"

func_assing_from_array
echo "HELLOJEE: ${HELLOJEE}"
echo "HELLOWEE: ${HELLOWEE}"
