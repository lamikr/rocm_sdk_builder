#!/bin/bash
#
# License of this file: "THE COFFEEWARE LICENSE" (Revision 2).
# see coffeeware file in the root directory for details.

# rocm release numbers
#
# Three first numbers are used for example to create a string that
# some applications like pytorch uses in #ifdefs
#
# In addition content of /etc/.info/version is bases on to these numbers
export ROCM_MAJOR_VERSION=6
export ROCM_MINOR_VERSION=1
export ROCM_PATCH_VERSION=1
export ROCM_SDK_RELEASE_VERSION=1

# Set BABS version information
export BABS_VERSION=2024_05_25_01

export ROCM_SDK_VERSION_INFO=rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
export UPSTREAM_REPO_VERSION_TAG_DEFAULT=rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
