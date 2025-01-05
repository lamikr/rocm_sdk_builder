# swithc first to users home dir inside docker image
cd
# then check if the rocm sdk builder env init script can and needs to be added
if [ -f ./.bashrc ]; then
    if [ -f /opt/rocm_sdk_612/bin/env_rocm.sh ]; then
        if ! grep -q "source /opt/rocm_sdk_612/bin/env_rocm.sh" ./.bashrc; then
            echo "# init rock_sdk_builder environment" >> ./.bashrc
            echo "source /opt/rocm_sdk_612/bin/env_rocm.sh" >> ./.bashrc
        else
            echo ".bashrc alredy has a line for: source /opt/rocm_sdk_612/bin/env_rocm.sh"
        fi
    else
        echo "/opt/rocm_sdk_612/bin/env_rocm.sh does not exist"
    fi
else
    echo ".bashrc does not exist"
fi
