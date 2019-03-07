#!/usr/bin/env zsh

set -e

readonly EXIT_CODE_NO_CMD=1
readonly EXIT_CODE_NO_FILES=2
readonly EXIT_CODE_NO_OUTPUT_FILE=3
readonly EXIT_CODE_INCOMPATIBLE_OPTIONS=4

readonly CMD_REPORT='report'
readonly CMD_FIX='fix'

function exec_gawk() {
  local args
  args=('-v' "$1")
  shift
  if [[ -n "$DEBUG" ]]; then
    args+=('-v' 'debug=1')
  fi
  local file
  for file in "$@"; do
    if [[ -n "$EDIT_IN_PLACE" ]]; then
      local tmp_file
      tmp_file=$(mktemp)
      # http://tldp.org/LDP/abs/html/io-redirection.html
      exec 3> "$tmp_file"
      exec 4< "$tmp_file"
      rm "$tmp_file"
      gawk -f zsh-escape.gawk "${args[@]}" "$file" >&3
      exec 3>&-
      cat <&4 > "$file"
      exec 4>&-
    elif [[ -n "$OUTPUT" ]]; then
      gawk -f zsh-escape.gawk "${args[@]}" "$file" >"$OUTPUT"
    else
      gawk -f zsh-escape.gawk "${args[@]}" "$file"
    fi
  done
  return "$?"
}

function report() {
  exec_gawk report=1 "$@"
  return "$?"
}

function fix() {
  exec_gawk fix=1 "$@"
  return "$?"
}

POSITIONAL=()
while [[ "$#" -gt 0 ]]; do
  key="$1"
  case "$key" in
    -d|--debug)
      DEBUG="true"
      shift # past argument
      ;;
    -o|--output)
      OUTPUT="$2"
      if [[ -z "$OUTPUT" ]]; then
        >&2 echo "Output file is missing"
        exit EXIT_CODE_NO_OUTPUT_FILE
      fi
      shift # past argument
      shift # past value
      ;;
    -i|--in-place)
      EDIT_IN_PLACE="true"
      shift # past argument
      ;;
    report)
      CMD="$CMD_REPORT"
      shift # past argument
      ;;
    fix)
      CMD="$CMD_FIX"
      shift # past argument
      ;;
    *) # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# TODO: Help text.

if [[ -z "$CMD" ]]; then
  >&2 echo "No command given."
  exit "$EXIT_CODE_NO_CMD"
fi

if [[ -n "$OUTPUT" && -n "$EDIT_IN_PLACE" ]]; then
  >&2 echo "--output and --in-place are incompatible options."
  exit "$EXIT_CODE_INCOMPATIBLE_OPTIONS"
fi

if [[ "$CMD" == "$CMD_REPORT" && -n "$EDIT_IN_PLACE" ]]; then
  >&2 echo "--in-place is not a valid option for the report command."
  exit "$EXIT_CODE_INCOMPATIBLE_OPTIONS"
fi

if [[ "$#" -eq 0 ]]; then
  >&2 echo "No files given."
  exit "$EXIT_CODE_NO_FILES"
fi

case "$CMD" in
$CMD_REPORT) report "$@" ;;
$CMD_FIX) fix "$@" ;;
esac
