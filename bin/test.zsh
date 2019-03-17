#!/usr/bin/env zsh

set -ex

[[ -v ZSH_ESCAPE_BIN_DIR ]] || readonly ZSH_ESCAPE_BIN_DIR="$( cd "$( dirname "${(%):-%N}" )" > /dev/null && pwd )"

export PATH="$PATH:$ZSH_ESCAPE_BIN_DIR/tush:$ZSH_ESCAPE_BIN_DIR/zsh-escape"

cd "$ZSH_ESCAPE_BIN_DIR/../test"
tush-check "$ZSH_ESCAPE_BIN_DIR/../README.md"
