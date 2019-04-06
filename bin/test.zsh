#!/usr/bin/env zsh

set -e

[[ -z "${ZSH_ESCAPE_BIN_DIR+x}" ]] || readonly ZSH_ESCAPE_BIN_DIR="$( cd "$( dirname "${(%):-%N}" )" > /dev/null && pwd )"

export PATH="$PATH:$ZSH_ESCAPE_BIN_DIR/tush:$ZSH_ESCAPE_BIN_DIR/zsh-escape"

cd "$ZSH_ESCAPE_BIN_DIR/../test"
tush-check "$ZSH_ESCAPE_BIN_DIR/../README.md"
