func_build_cfg_user() {
    ./build/checkbox.sh --message="Select ROCM SDK build target GPUs. Space to select, Enter to finish save, ESC to cancel." --options="gfx906|gfx90a|gfx940|gfx1010|gfx1011|gfx1012|gfx1030|gfx1031|gfx1035|gfx1100|gfx1101|gfx1102|gfx1150|gfx1151" --multiple
}
