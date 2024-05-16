#
# Copyright (c) 2024 by Mika Laitio <lamikr@gmail.com>
#
# License: GNU Lesser General Public License (LGPL), version 2.1 or later.
# See the lgpl.txt file in the root directory or <http://www.gnu.org/licenses/lgpl-2.1.html>.
#

func_binfo_utils__init_binfo_app_list() {
    LIST_BINFO_FILE_FULLNAME=()
    LIST_BINFO_APP_NAME=()
    LIST_APP_SRC_DIR=()
    LIST_APP_SRC_CLONE_DIR=()
    LIST_APP_PATCH_DIR=()
    LIST_APP_UPSTREAM_REPO_URL=()
    LIST_APP_UPSTREAM_REPO_DEFINED=()
    LIST_REPO_REVS_NEW=()
    LIST_REPO_REVS_CUR=()
    jj=0
    while [ "x${LIST_BINFO_FILE_BASENAME[jj]}" != "x" ]
    do
        #echo ${LIST_BINFO_FILE_BASENAME[jj]}

        unset BINFO_APP_UPSTREAM_REPO_URL
        unset BINFO_APP_SRC_CLONE_DIR
        unset BINFO_APP_SRC_DIR
        unset BINFO_APP_NAME
        unset BINFO_APP_UPSTREAM_REPO_VERSION_TAG

        LIST_BINFO_FILE_FULLNAME[$jj]=${SDK_ROOT_DIR}/binfo/${LIST_BINFO_FILE_BASENAME[${jj}]}

        #read build commands
        source ${LIST_BINFO_FILE_FULLNAME[${jj}]}
        if [ -v BINFO_APP_SRC_CLONE_DIR ]; then
            LIST_APP_SRC_CLONE_DIR[$jj]=${BINFO_APP_SRC_CLONE_DIR}
        else
            if [ -v BINFO_APP_SRC_DIR ]; then
                LIST_APP_SRC_CLONE_DIR[$jj]=${BINFO_APP_SRC_DIR}
            else
                echo "error, define for variable BINFO_APP_SRC_DIR missing: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
                exit 1
            fi
        fi

        if [ -v BINFO_APP_SRC_DIR ]; then
            LIST_APP_SRC_DIR[$jj]=${BINFO_APP_SRC_DIR}
        else
            echo "error, define for variable BINFO_APP_SRC_DIR missing: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            exit 1
        fi
        if [ -v BINFO_APP_NAME ]; then
            LIST_BINFO_APP_NAME[$jj]=${BINFO_APP_NAME}
            LIST_APP_PATCH_DIR[$jj]=${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}
        else
            echo "error, BINFO_APP_NAME npt defined: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            exit 1
        fi
        if [ -v BINFO_APP_UPSTREAM_REPO_URL ]; then
            if [ "x${BINFO_APP_UPSTREAM_REPO_URL}" != "x" ]; then
                LIST_APP_UPSTREAM_REPO_URL[$jj]=${BINFO_APP_UPSTREAM_REPO_URL}
                LIST_APP_UPSTREAM_REPO_DEFINED[$jj]=1
            else
                LIST_APP_UPSTREAM_REPO_URL[$jj]=
                LIST_APP_UPSTREAM_REPO_DEFINED[$jj]=0
                #echo "empty repo url in project: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            fi
        else
            #echo "warning, BINFO_APP_UPSTREAM_REPO_URL not defined: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            LIST_APP_UPSTREAM_REPO_URL[$jj]=
            LIST_APP_UPSTREAM_REPO_DEFINED[$jj]=0
        fi

        if [ -v BINFO_APP_UPSTREAM_REPO_VERSION_TAG ]; then
            LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]=${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}
            #echo "BINFO_APP_UPSTREAM_REPO_VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
        else
            #echo "UPSTREAM_REPO_VERSION_TAG_DEFAULT: ${UPSTREAM_REPO_VERSION_TAG_DEFAULT}"
            LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}
            #echo "error, define for variable BINFO_APP_REPO_VERSION_TAG missing: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            #exit 1
        fi
        jj=$(( ${jj} + 1 ))
    done
}

#FNAME_REPO_REVS_CUR=${SDK_ROOT_DIR}/repo_revs_cur.txt
#FNAME_REPO_REVS_NEW=${SDK_ROOT_DIR}/repo_revs_new.txt
