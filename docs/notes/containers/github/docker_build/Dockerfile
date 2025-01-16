FROM ubuntu:24.04

ARG ENV_VAR__TARGET_GPU_CFG_FILE_ALL=docs/notes/containers/config/build_cfg_all.user
ARG ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED=docs/notes/containers/config/build_cfg_cdna.user

ARG ENV_VAR__TARGET_GPU_CFG_FILE_RDNA12=docs/notes/containers/config/build_cfg_rdna1_rdna2.user
ARG ENV_VAR__TARGET_GPU_CFG_FILE_RDNA3=docs/notes/containers/config/build_cfg_rdna3.user
ARG ENV_VAR__TARGET_GPU_CFG_FILE_CDNA=docs/notes/containers/config/build_cfg_cdna.user
ARG ENV_VAR__TARGET_GPU_CFG_FILE=docs/notes/containers/config/build_cfg_cdna.user
ARG ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED=docs/notes/containers/config/build_cfg_cdna.user

WORKDIR /
RUN apt update && apt install -y git git-lfs sudo vim
RUN git clone --recursive https://github.com/lamikr/rocm_sdk_builder.git
RUN cd rocm_sdk_builder && git checkout master

# example how to apply updates to image during the build time
# RUN cd /rocm_sdk_builder && git reset --hard HEAD~1 && ./babs.sh -up
RUN cd rocm_sdk_builder && ./docs/notes/containers/scripts/preconfig_ubuntu.sh
RUN ./docs/notes/containers/scripts/select_target_gpus.sh ${ENV_VAR__TARGET_GPU_CFG_FILE_ALL}
RUN cd rocm_sdk_builder && ./babs.sh -b binfo/core/001_rocm_core.binfo
RUN cd rocm_sdk_builder && ./babs.sh -b binfo/core/002_01_cmake_backport.binfo
RUN cd rocm_sdk_builder && ./babs.sh -b binfo/core/002_02_zstd_backport.binfo
RUN cd rocm_sdk_builder && ./babs.sh -b binfo/core/002_03_python_backport.binfo
RUN cd rocm_sdk_builder && ./babs.sh -b binfo/core/002_04_ffmpeg7_devel.binfo
