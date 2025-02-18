#!/bin/bash

export TMPFS=/opt/containers/run
export TMPDIR=/opt/containers/run

BUILD_CMD_ARRAY=(
    "RUN cd rocm_sdk_builder && ./docs/notes/containers/docker_build/scripts/download_binfo_src.sh"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p1.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p2.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p3.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p4.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p5.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p4.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p6.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p7.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p8.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p9.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p10.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_core_p11.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_extra_p1.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_extra_p2.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_extra_p3.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b docs/notes/containers/docker_build/blist/binfo_extra_p4.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b binfo/extra/amd_media_tools.blist"
    "RUN cd rocm_sdk_builder && ./babs.sh -b binfo/extra/ai_tools.blist"
    "RUN /rocm_sdk_builder/docs/notes/containers/docker_build/scripts/docker_image_post_build__cleanup_src_and_builddir.sh"
    "RUN /rocm_sdk_builder/docs/notes/containers/docker_build/scripts/docker_image_post_build__cleanup_third_party_caches.sh"
    "RUN /rocm_sdk_builder/docs/notes/containers/docker_build/scripts/docker_image_post_build__add_rocm_sdk_to_bashrc_env.sh"
)

func_build_rocm_container_image() {
    local ii

    echo "Stating the ROCM SDK Builder container build"
    echo "Building for target: ${ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED}"
    echo "Remember that build needs to be run usually by user root-user to work"
    sleep 4
    if [ -e Dockerfile ]; then
        echo ""
        echo "Error, Dockerfile exist. Remove it before starting a new build"
        exit 1
    else
        echo ""
        echo "Copying Dockerfile_template to Dockerfile"
        cp -f Dockerfile_template Dockerfile
    fi
    if [ ! -d /opt/containers/run ]; then
        mkdir -p /opt/containers/run
    fi
    
    echo ""
    echo "Building first basic ubuntu image" 
    # create basic ubuntu image first
    podman build -t ${PODMAN_IMG_NAME} --build-arg ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED .
    RES=$?
    if [ ${RES} -eq 0 ]; then
        echo "Base image created for rocm sdk builder container"
    else
        echo "Failed to create base image created for rocm sdk builder container"
        exit 1
    fi
    ii=0
    if [[ ${BUILD_CMD_ARRAY[@]} ]]; then
        local CUR_BUILD_CMD
        for CUR_BUILD_CMD in "${BUILD_CMD_ARRAY[@]}"; do
            if [ ! -z CUR_BUILD_CMD ]; then
                echo "Executing command: ${CUR_BUILD_CMD}"
                echo ${CUR_BUILD_CMD} >> Dockerfile
                podman build -t ${PODMAN_IMG_NAME} --build-arg ENV_VAR__TARGET_GPU_CFG_FILE_SELECTED .
                RES=$?
                if [ ${RES} -eq 0 ]; then
                    echo "Build phase done: ${CUR_BUILD_CMD}"
                else
                    echo "Error, failed to execute build command: ${CUR_BUILD_CMD}"
                    exit 1
                fi
            fi
        done
    else
        echo "Error, invalid in build command array"
        echo "    $1"
        echo ""
        exit 1
    fi
}

