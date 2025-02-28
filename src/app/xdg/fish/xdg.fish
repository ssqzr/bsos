set -q XDG_CACHE_HOME || set -x XDG_CACHE_HOME $HOME/.cache
set -q XDG_CONFIG_HOME || set -x XDG_CONFIG_HOME $HOME/.config
set -q XDG_DATA_HOME || set -x XDG_DATA_HOME $HOME/.local/share
set -q XDG_STATE_HOME || set -x XDG_RUNTIME_DIR $HOME/.local/state
