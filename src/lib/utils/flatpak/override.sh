#!/bin/bash

if [ -n "${SCRIPT_DIR_83277c97}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_83277c97="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_83277c97}/../constant.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_83277c97}/../parameter.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_83277c97}/../string.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_83277c97}/../array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_83277c97}/../cmd.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_83277c97}/../fs/fs.sh"

function flatpak::override::permission::_gen_option_name() {
    local permission="$1"
    shift
    local policy="$1"
    shift

    local name
    # shellcheck disable=SC2034
    local valid_policy=("allow" "deny" "unset")
    if array::is_not_contain valid_policy "$policy"; then
        lerror "invalid policy $policy"
        return "$SHELL_FALSE"
    fi

    case "$permission" in
    socket | device | filesystem)
        if [ "$policy" = "allow" ]; then
            name="--${permission}"
        elif [ "$policy" = "deny" ]; then
            name="--no${permission}"
        fi
        ;;
    share)
        if [ "$policy" = "allow" ]; then
            name="--${permission}"
        elif [ "$policy" = "deny" ]; then
            name="--un${permission}"
        fi
        ;;
    allow)
        if [ "$policy" = "allow" ]; then
            name="--${permission}"
        elif [ "$policy" = "deny" ]; then
            name="--dis${permission}"
        fi
        ;;
    env)
        if [ "$policy" = "allow" ]; then
            name="--${permission}"
        elif [ "$policy" = "deny" ]; then
            name="--unset-${permission}"
        fi
        ;;
    env-fd | system-own-name)
        if [ "$policy" = "allow" ]; then
            name="--${permission}"
        else
            lerror "${permission} is not support in policy ${policy}"
            return "$SHELL_FALSE"
        fi
        ;;
    talk-name)
        if [ "$policy" = "allow" ]; then
            name="--${permission}"
        elif [ "$policy" = "deny" ]; then
            name="--no-${permission}"
        fi
        ;;
    system-talk-name)
        if [ "$policy" = "allow" ]; then
            name="--system-talk-name"
        elif [ "$policy" = "deny" ]; then
            name="--system-no-talk-name"
        fi
        ;;
    policy)
        if [ "$policy" = "allow" ]; then
            name="--add-${permission}"
        elif [ "$policy" = "deny" ]; then
            name="--remove-${permission}"
        fi
        ;;
    persist)
        if [ "$policy" = "allow" ]; then
            name="--${permission}"
        else
            lerror "${permission} is not support in policy ${policy}"
        fi
        ;;
    *)
        lerror "unknown permission $permission"
        return "$SHELL_FALSE"
        ;;
    esac

    printf "%s" "$name" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function flatpak::override::permission::set() {
    local permission
    local value
    local scope
    local app
    local policy

    local options=()
    local is_sudo="$SHELL_FALSE"
    local permission_name
    local param

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        --policy=*)
            parameter::parse_string --option="$param" policy || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v permission ]; then
                permission="$param"
                continue
            fi

            if [ ! -v value ]; then
                value="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    if [ ! -v permission ]; then
        lerror "param permission is not set"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$permission"; then
        lerror "param permission is empty"
        return "$SHELL_FALSE"
    fi

    if string::is_empty "$scope" || [ "$scope" == "system" ]; then
        is_sudo="$SHELL_TRUE"
    elif [ "$scope" == "user" ]; then
        is_sudo="$SHELL_FALSE"
        options+=("--user")
    else
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
    fi

    permission_name="$(flatpak::override::permission::_gen_option_name "$permission" "$policy")" || return "$SHELL_FALSE"
    options+=("${permission_name}=${value}")

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" -- flatpak override "${options[@]}" "$app" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function flatpak::override::filesystem::allow() {
    local filesystem
    local scope
    local app

    local param

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v filesystem ]; then
                filesystem="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    flatpak::override::permission::set --scope="$scope" --app="$app" --policy=allow "filesystem" "$filesystem" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function flatpak::override::filesystem::deny() {
    local filesystem
    local scope
    local app

    local param

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v filesystem ]; then
                filesystem="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    flatpak::override::permission::set --scope="$scope" --app="$app" --policy=deny "filesystem" "$filesystem" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 通过修改配置文件的方式清除
function flatpak::override::filesystem::_unset() {
    local scope="$1"
    shift
    local filesystem="$1"
    shift
    local is_deny="$1"
    shift
    local app="$1"
    shift

    local param
    local config_filepath
    local temp_str
    local filesystems=()
    local is_sudo="$SHELL_FALSE"

    ldebug "param scope=$scope, filesystem=$filesystem, is_deny=$is_deny, app=$app"

    if string::is_empty "$scope" || [ "$scope" == "system" ]; then
        is_sudo="$SHELL_TRUE"
    elif [ "$scope" == "user" ]; then
        is_sudo="$SHELL_FALSE"
    else
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
    fi

    case "$scope" in
    system)
        config_filepath="/var/lib/flatpak/overrides"
        ;;
    user)
        config_filepath="$HOME/.local/share/flatpak/overrides"
        ;;
    *)
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
        ;;
    esac

    if string::is_empty "$app"; then
        config_filepath="${config_filepath}/global"
    else
        config_filepath="${config_filepath}/$app"
    fi
    ldebug "config file=$config_filepath"

    if fs::path::is_not_exists "$config_filepath"; then
        ldebug "config file($config_filepath) is not exists, not need unset"
        return "$SHELL_TRUE"
    fi

    if [ "$is_deny" == "$SHELL_TRUE" ]; then
        filesystem="!${filesystem}"
    fi

    temp_str=$(grep -E "^filesystems=" "$config_filepath" | awk -F '=' '{print $2}')
    ldebug "current filesystems=$temp_str"

    if string::is_empty "$temp_str"; then
        ldebug "filesystems is not set in config file($config_filepath), not need unset"
        return "$SHELL_TRUE"
    fi

    string::split_with filesystems "$temp_str" ";" || return "$SHELL_FALSE"
    ldebug "filesystems=(${filesystems[*]})"

    array::remove filesystems "$filesystem" || return "$SHELL_FALSE"

    temp_str="$(array::join_with filesystems ";")" || return "$SHELL_FALSE"

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" -- sed -i "{{s|^filesystems=.*|filesystems=${temp_str}|g}}" "$config_filepath" || return "$SHELL_FALSE"

    linfo "remove filesystem $filesystem success, scope=$scope, app=$app, is_deny=$is_deny"

    return "$SHELL_TRUE"
}

# 通过修改配置文件的方式清除
function flatpak::override::filesystem::allow_unset() {
    local filesystem
    local scope
    local app

    local param

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v filesystem ]; then
                filesystem="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    ldebug "param filesystem=$filesystem scope=$scope app=$app"

    flatpak::override::filesystem::_unset "$scope" "$filesystem" "$SHELL_FALSE" "$app" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# 通过修改配置文件的方式清除
function flatpak::override::filesystem::deny_unset() {
    local filesystem
    local scope
    local app

    local param

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v filesystem ]; then
                filesystem="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    ldebug "param filesystem=$filesystem scope=$scope app=$app"

    flatpak::override::filesystem::_unset "$scope" "$filesystem" "$SHELL_TRUE" "$app" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function flatpak::override::environment::allow() {
    local name
    local value
    local scope
    local app

    local param

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v name ]; then
                name="$param"
                continue
            fi

            if [ ! -v value ]; then
                value="$param"
                continue
            fi
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    ldebug "param scope=$scope, app=$app, name=$name, value=$value"

    flatpak::override::permission::set --scope="$scope" --app="$app" --policy=allow "env" "$name=$value" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function flatpak::override::environment::allow_unset() {
    local name
    local scope
    local app

    local param
    local is_sudo="$SHELL_FALSE"
    local config_filepath

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            if [ ! -v name ]; then
                name="$param"
                continue
            fi

            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    ldebug "param scope=$scope, app=$app, name=$name"

    if string::is_empty "$scope" || [ "$scope" == "system" ]; then
        is_sudo="$SHELL_TRUE"
    elif [ "$scope" == "user" ]; then
        is_sudo="$SHELL_FALSE"
    else
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
    fi

    case "$scope" in
    system)
        config_filepath="/var/lib/flatpak/overrides"
        ;;
    user)
        config_filepath="$HOME/.local/share/flatpak/overrides"
        ;;
    *)
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
        ;;
    esac

    if string::is_empty "$app"; then
        config_filepath="${config_filepath}/global"
    else
        config_filepath="${config_filepath}/$app"
    fi
    ldebug "config file=$config_filepath"

    if fs::path::is_not_exists "$config_filepath"; then
        ldebug "config file($config_filepath) is not exists, not need unset"
        return "$SHELL_TRUE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" -- sed -i "{{s/^${name}=.*//g}}" "$config_filepath" || return "$SHELL_FALSE"

    linfo "remove env success. scope=$scope, app=$app, name=$name"

    return "$SHELL_TRUE"
}

function flatpak::override::reset {
    local scope
    local app

    local param
    local is_sudo="$SHELL_FALSE"
    local options=()

    for param in "$@"; do
        case "$param" in
        --scope=*)
            parameter::parse_string --option="$param" scope || return "$SHELL_FALSE"
            ;;
        --app=*)
            parameter::parse_string --option="$param" app || return "$SHELL_FALSE"
            ;;
        -*)
            lerror "unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            lerror "unknown parameter $param"
            return "$SHELL_FALSE"
            ;;
        esac
    done

    ldebug "param scope=$scope, app=$app"

    if string::is_empty "$scope" || [ "$scope" == "system" ]; then
        is_sudo="$SHELL_TRUE"
    elif [ "$scope" == "user" ]; then
        is_sudo="$SHELL_FALSE"
        options+=("--user")
    else
        lerror "unknown scope $scope"
        return "$SHELL_FALSE"
    fi

    cmd::run_cmd_with_history --sudo="$(string::print_yes_no "$is_sudo")" -- flatpak override "${options[@]}" --reset "$app" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}
