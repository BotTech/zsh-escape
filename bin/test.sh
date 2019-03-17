#!/usr/bin/env bash

set -e

[[ -v ZSH_ESCAPE_BIN_DIR ]] || readonly ZSH_ESCAPE_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

export PATH="$PATH:$ZSH_ESCAPE_BIN_DIR/tush:$ZSH_ESCAPE_BIN_DIR/zsh-escape"

cd "$ZSH_ESCAPE_BIN_DIR/../test"
tush-check "$ZSH_ESCAPE_BIN_DIR/../README.md"
