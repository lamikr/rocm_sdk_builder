#!/bin/bash

# License of this file: "THE COFFEEWARE LICENSE" (Revision 2).
# See coffeeware file in the root directory for details.

# Set ROCM version information
# these numbers are visible on /etc/.info/version
# ROCM_SDK_RELEASE_VERSION is the fourth number and meant to used for reporting the tagged sdk releases
export ROCM_MAJOR_VERSION=6
export ROCM_MINOR_VERSION=1
export ROCM_PATCH_VERSION=1
export ROCM_SDK_RELEASE_VERSION=1

# Set BABS version information
export BABS_VERSION=2024_05_25_01

# Construct the full ROCM SDK version info string
export ROCM_SDK_VERSION_INFO="rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}"

# Set the default upstream repo version tag
export UPSTREAM_REPO_VERSION_TAG_DEFAULT="rocm-${ROCM_MAJOR_VERSION}.${ROCM_MINOR_VERSION}.${ROCM_PATCH_VERSION}"

# Print the set variables (optional, for debugging)
echo "ROCM_MAJOR_VERSION=${ROCM_MAJOR_VERSION}"
echo "ROCM_MINOR_VERSION=${ROCM_MINOR_VERSION}"
echo "ROCM_PATCH_VERSION=${ROCM_PATCH_VERSION}"
echo "BABS_VERSION=${BABS_VERSION}"
echo "ROCM_SDK_VERSION_INFO=${ROCM_SDK_VERSION_INFO}"
echo "UPSTREAM_REPO_VERSION_TAG_DEFAULT=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}"
