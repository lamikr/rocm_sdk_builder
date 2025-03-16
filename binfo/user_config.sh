#!/bin/bash

# Function to select ROCM SDK build target GPUs
func_build_cfg_user() {
    local message="Select ROCM SDK build target GPUs. Space to select, Enter to finish save, ESC to cancel."
    local options="gfx906 (MI50/Radeon VII)|gfx908 (MI100)|gfx90a (MI210/250/250X)|gfx940 (MI300A)|gfx941 (MI300X)|gfx942 (MI300A/MI300X)|gfx1010 (Radeon RX 5600/5700)|gfx1011 (Radeon Pro V520)|gfx1012 (Radeon RX 5500)|gfx1030 (Radeon RX 6800/6900)|gfx1031 (Radeon RX 6700)|gfx1032 (Radeon RX 6600/6500)|gfx1035 (AMD Radeon 680M laptop iGPU)|gfx1036 (AMD Radeon 680M desktop iGPU)|gfx1100 (AMD Radeon 7900/7950)|gfx1101 (AMD Radeon 7700/7800)|gfx1102 (AMD Radeon 7500/7600/7700S)|gfx1103 (AMD Radeon 780M laptop iGPU)|gfx1150 (AMD Strix Point laptop iGPU)|gfx1151 (AMD Ryzen 395 Strix Halo iGPU)|gfx1200 (AMD Navi 44)|gfx1201 (AMD 9070/9070 XT)"
    local script_path="./build/checkbox.sh"

    # Check if the script exists and is executable
    if [[ ! -x "$script_path" ]]; then
        echo "Error: $script_path not found or not executable."
        return 1
    fi

    # Execute the checkbox script with the specified parameters
    "$script_path" --message="$message" --options="$options" --multiple
}
