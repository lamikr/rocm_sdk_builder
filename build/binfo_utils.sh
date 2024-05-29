#!/bin/bash
# Copyright (c) 2024 by Mika Laitio <lamikr@gmail.com>
# License: GNU Lesser General Public License (LGPL), version 2.1 or later.
# See the lgpl.txt file in the root directory or <http://www.gnu.org/licenses/lgpl-2.1.html>.

func_binfo_utils__init_binfo_app_list() {
    # Initialize arrays
    LIST_BINFO_APP_NAME=()
    LIST_BINFO_FILE_FULLNAME=()
    LIST_APP_SRC_DIR=()
    LIST_APP_SRC_CLONE_DIR=()
    LIST_APP_PATCH_DIR=()
    LIST_APP_UPSTREAM_REPO_URL=()
    LIST_APP_UPSTREAM_REPO_DEFINED=()
    LIST_REPO_REVS_NEW=()
    LIST_REPO_REVS_CUR=()

    local jj=0
    while [[ -n "${LIST_BINFO_FILE_BASENAME[jj]}" ]]; do
        unset BINFO_APP_UPSTREAM_REPO_URL
        unset BINFO_APP_SRC_CLONE_DIR
        unset BINFO_APP_SRC_DIR
        unset BINFO_APP_NAME
        unset BINFO_APP_UPSTREAM_REPO_VERSION_TAG

        # Define full path to the binfo file
        LIST_BINFO_FILE_FULLNAME[jj]="${SDK_ROOT_DIR}/binfo/${LIST_BINFO_FILE_BASENAME[jj]}"

        # Source the binfo file to read build commands
        source "${LIST_BINFO_FILE_FULLNAME[jj]}"

        # Initialize source clone directory
        if [[ -n "${BINFO_APP_SRC_CLONE_DIR}" ]]; then
            LIST_APP_SRC_CLONE_DIR[jj]="${BINFO_APP_SRC_CLONE_DIR}"
        elif [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
            LIST_APP_SRC_CLONE_DIR[jj]="${BINFO_APP_SRC_DIR}"
        else
            echo "Error: BINFO_APP_SRC_DIR not defined in ${LIST_BINFO_FILE_FULLNAME[jj]}"
            exit 1
        fi

        # Initialize source directory
        if [[ -n "${BINFO_APP_SRC_DIR-}" ]]; then
            LIST_APP_SRC_DIR[jj]="${BINFO_APP_SRC_DIR}"
        else
            echo "Error: BINFO_APP_SRC_DIR not defined in ${LIST_BINFO_FILE_FULLNAME[jj]}"
            exit 1
        fi

        # Initialize application name and patch directory
        if [[ -n "${BINFO_APP_NAME-}" ]]; then
            LIST_BINFO_APP_NAME[jj]="${BINFO_APP_NAME}"
            LIST_APP_PATCH_DIR[jj]="${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}"
        else
            echo "Error: BINFO_APP_NAME not defined in ${LIST_BINFO_FILE_FULLNAME[jj]}"
            exit 1
        fi

        # Initialize upstream repository URL and definition status
        if [[ -n "${BINFO_APP_UPSTREAM_REPO_URL-}" ]]; then
            LIST_APP_UPSTREAM_REPO_URL[jj]="${BINFO_APP_UPSTREAM_REPO_URL}"
            LIST_APP_UPSTREAM_REPO_DEFINED[jj]=1
        else
            LIST_APP_UPSTREAM_REPO_URL[jj]=""
            LIST_APP_UPSTREAM_REPO_DEFINED[jj]=0
        fi

        # Initialize upstream repository version tag
        if [[ -n "${BINFO_APP_UPSTREAM_REPO_VERSION_TAG-}" ]]; then
            LIST_APP_UPSTREAM_REPO_VERSION_TAG[jj]="${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
        else
            LIST_APP_UPSTREAM_REPO_VERSION_TAG[jj]="${UPSTREAM_REPO_VERSION_TAG_DEFAULT}"
        fi

        ((jj++))
    done
}