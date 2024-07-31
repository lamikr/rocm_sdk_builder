#!/bin/bash
#
# License of this file: "THE COFFEEWARE LICENSE" (Revision 2).
# see coffeeware file in the root directory for details.

# rocm release numbers
#
# Three first numbers are used for example to create a string that
# some applications like pytorch uses in #ifdefs
#
# In addition content of /opt/rocm_sdk_xyz/.info/version is bases on to these numbers
export ROCM_MAJOR_VERSION=6
export ROCM_MINOR_VERSION=1
export ROCM_PATCH_VERSION=2
export ROCM_SDK_RELEASE_VERSION=1

# Set BABS version information
# Stored in /opt/rocm_sdk_xyz/.info/rocm_sdk_builder
export BABS_VERSION=2024_07_31_01

# Get git hash used to build the system
# Stored in /opt/rocm_sdk_xyz/.info/rocm_sdk_builder
export ROCM_SDK_BUILDER_SRC_REV=$(git rev-parse --short=8 HEAD)

export ROCM_SDK_VERSION_INFO=rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
export UPSTREAM_REPO_VERSION_TAG_DEFAULT=rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}
