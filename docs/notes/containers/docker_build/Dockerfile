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

# build first rocm adk builder base libs for all possible GPU's. 
# Each target gpu increases build time significantly, so it's slow operation
RUN cd rocm_sdk_builder && ./docs/notes/containers/scripts/select_target_gpus.sh ${ENV_VAR__TARGET_GPU_CFG_FILE_ALL}
RUN cd rocm_sdk_builder && ./docs/notes/containers/scripts/download_binfo_src.sh
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p1.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p2.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p3.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p4.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p5.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p4.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p6.blist

# rest of the libs will grow too big if we build them for all targets, causing linker errors
# on apps like pytorch.
# So we build rest of the image only for a smaller amount of target GPUs
RUN cd rocm_sdk_builder && ./docs/notes/containers/scripts/select_target_gpus.sh ${ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED}
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p7.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p8.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p9.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p10.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_core_p11.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_extra_p1.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_extra_p2.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_extra_p3.blist
RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/blist/binfo_extra_p4.blist
RUN cd rocm_sdk_builder && ./babs.sh -b binfo/extra/amd_media_tools.blist
RUN cd rocm_sdk_builder && ./babs.sh -b binfo/extra/ai_tools.blist
# cleanup and finalize the image
RUN /rocm_sdk_builder/docs/notes/containers/scripts/docker_image_post_build__cleanup_src_and_builddir.sh
RUN /rocm_sdk_builder/docs/notes/containers/scripts/docker_image_post_build__cleanup_third_party_caches.sh
RUN /rocm_sdk_builder/docs/notes/containers/scripts/docker_image_post_build__add_rocm_sdk_to_bashrc_env.sh
