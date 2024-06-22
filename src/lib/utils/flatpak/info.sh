#!/bin/bash

if [ -n "${SCRIPT_DIR_587697e5}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_587697e5="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_587697e5}/../constant.sh"

function flatpak::info::ref() {
    local scope
    local app

    local param
    local options=()
    local output

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v app ]; then
                app="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    ldebug "param scope=$scope, app=$app"

    if [ ! -v app ]; then
        lerror "param app is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$app"; then
        lerror "param app is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$scope" == "system" ]; then
        options+=("--system")
    elif [ "$scope" == "user" ]; then
        options+=("--user")
    elif string::is_not_empty "$scope"; then
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
    fi

    output="$(flatpak info "${options[@]}" -r "$app" 2>&1)"
    if [ $? != "$SHELL_TRUE" ]; then
        lerror "flatpak info $app failed, error=$output"
        return "$SHELL_FALSE"
    fi

    printf "%s" "$output"

    return "$SHELL_TRUE"
}

function flatpak::info::location() {
    local scope
    local app

    local param
    local options=()
    local output

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v app ]; then
                app="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    ldebug "param scope=$scope, app=$app"

    if [ ! -v app ]; then
        lerror "param app is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$app"; then
        lerror "param app is empty"
        return "$SHELL_FALSE"
    fi

    if [ "$scope" == "system" ]; then
        options+=("--system")
    elif [ "$scope" == "user" ]; then
        options+=("--user")
    elif string::is_not_empty "$scope"; then
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
    fi

    output="$(flatpak info "${options[@]}" -l "$app" 2>&1)"
    if [ $? != "$SHELL_TRUE" ]; then
        lerror "flatpak info $app failed, error=$output"
        return "$SHELL_FALSE"
    fi

    printf "%s" "$output"

    return "$SHELL_TRUE"
}
