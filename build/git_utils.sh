#!/bin/bash

func_is_current_dir_a_git_submodule_dir() {
    if [ -f .gitmodules ]; then
        echo ".gitmodules file exists"
        if [ "$(wc -w < .gitmodules)" -gt 0 ]; then
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

func_is_current_dir_a_git_repo_dir() {
    local inside_git_repo
    inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
    if [ "$inside_git_repo" ]; then
        return 0  # is a git repo
    else
        return 1  # not a git repo
    fi
    #git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

func_is_git_configured() {
    local GIT_USER_NAME
    local GIT_USER_EMAIL

    GIT_USER_NAME=$(git config --get user.name)
    if [[ -n "$GIT_USER_NAME" ]]; then
        GIT_USER_EMAIL=$(git config --get user.email)
        if [[ -n "$GIT_USER_EMAIL" ]]; then
            return 0
        else
            echo ""
            echo "You need to configure git user's email address. Example command:"
            echo "    git config --global user.email \"john.doe@emailserver.com\""
            echo ""
            exit 2
        fi
    else
        echo ""
        echo "You need to configure git user's name and email address. Example commands:"
        echo "    git config --global user.name \"John Doe\""
        echo "    git config --global user.email \"john.doe@emailserver.com\""
        echo ""
        exit 2
    fi
}