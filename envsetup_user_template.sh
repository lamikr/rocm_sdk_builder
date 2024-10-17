# This file is an example how to override the default build
# variables for defining the installation directory and the amount
# of CPU's used for building the SDK.
#
# Because some applications requires during the build and link time more
# memory there are 3 different variables for specifying the CPU_COUNT
# to allow each of the builded applications to override the default
# CPU count if needed.
#
# You can get overried the variables with following steps.
# 1) copy example file to envsetup_user.sh with command:
#
#    cp envsetup_user_template.sh envsetup_user.sh
#
# 2) Remove the '#' character from the lines defining
# the variables and their values below so that they get actiated
# for the values you want to define/override.

#export INSTALL_DIR_PREFIX_SDK_AI_MODELS=~/rocm/rocm_sdk_models
#export INSTALL_DIR_PREFIX_SDK_ROOT=~/rocm/rocm_sdk_612
#export BUILD_CPU_COUNT_DEFAULT=8
#export BUILD_CPU_COUNT_MODERATE=8
#export BUILD_CPU_COUNT_SAFE=8
