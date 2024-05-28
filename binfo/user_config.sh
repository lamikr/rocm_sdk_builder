#!/bin/bash

# Function to select ROCM SDK build target GPUs
func_build_cfg_user() {
    local message="Select ROCM SDK build target GPUs. Space to select, Enter to finish save, ESC to cancel."
    local options="gfx906|gfx90a|gfx940|gfx1010|gfx1011|gfx1012|gfx1030|gfx1031|gfx1035|gfx1100|gfx1101|gfx1102|gfx1150|gfx1151"
    local script_path="./build/checkbox.sh"

    # Check if the script exists and is executable
    if [[ ! -x "$script_path" ]]; then
        echo "Error: $script_path not found or not executable."
        return 1
    fi

    # Execute the checkbox script with the specified parameters
    "$script_path" --message="$message" --options="$options" --multiple
}