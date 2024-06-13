#!/bin/bash

# Function to select ROCM SDK build target GPUs
func_build_cfg_user() {
    local gpu_message="Select ROCM SDK build target GPUs. Space to select, Enter to finish save, ESC to cancel."
    local gpu_options="gfx906|gfx90a|gfx940|gfx1010|gfx1011|gfx1012|gfx1030|gfx1031|gfx1035|gfx1100|gfx1101|gfx1102|gfx1150|gfx1151"
    local script_path="./build/checkbox.sh"

    # Check if the script exists and is executable
    if [[ ! -x "$script_path" ]]; then
        echo "Error: $script_path not found or not executable."
        return 1
    fi

    # Execute the checkbox script with the specified parameters
    "$script_path" --message="$gpu_message" --options="$gpu_options" --multiple

    py_options=("v3.9.19" "v3.10.14" "v3.11.9" "v3.12.4")

    # Function to display the menu
    show_menu() {
        echo "Select a Python version to use:"
        for i in "${!py_options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "\033[1;32m> ${py_options[$i]}\033[0m"  # Highlight the selected option
            else
                echo "  ${py_options[$i]}"
            fi
        done
    }

    # Function to handle key press
    navigate_menu() {
        read -rsn1 key
        case $key in
            "")    # Enter key
                return 0
                ;;
            $'\x1B')  # Escape sequence
                read -rsn2 key
                if [ "$key" == "[A" ]; then  # Up arrow
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((${#py_options[@]} - 1))
                    fi
                elif [ "$key" == "[B" ]; then  # Down arrow
                    ((selected++))
                    if [ $selected -ge ${#py_options[@]} ]; then
                        selected=0
                    fi
                fi
                ;;
        esac
        return 1
    }

    # Main script execution
    selected=0

    while true; do
        clear
        show_menu
        if navigate_menu; then
            selected_version="${py_options[$selected]}"
            echo "You have selected: $selected_version"
            echo "$selected_version" > python_cfg.user
            clear
            break
        fi
    done  
}
