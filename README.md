# Zsh Escape

Zsh Escape is a Zsh script for finding and automatically fixing unescaped variables in Zsh scripts.

## Prerequisites

* zsh
* gawk

## Usage

### Report

It can be helpful to run the `report` command first.
This will go through each line in a file and print the line number followed by any potential errors.

`./zsh-escape.zsh report [OPTION]... [FILE]...`

#### Options

Option | Value | Description
------ | ----- | -----------
`-d` `--debug` |  | Includes debugging output.
`-o` `--output` | `<file>` | Writes the output to a file.

#### Example

```zsh
zsh-escape.zsh report C:\source\antigen\bin\antigen.zsh
```
```text
...
12 : # While boot.zsh is part of the ext/cache functionallity it may be disabled
13 : # with ANTIGEN_CACHE flag, and it's always compiled with antigen.zsh
14 : if [[ $ANTIGEN_CACHE != false ]]; then
- Unescaped variable: $ANTIGEN_CACHE
- Found an unescaped variable
...
```

This shows that it found an unescaped variable `$ANTIGEN_CACHE`.

### Fix

The `fix` command will automatically add missing quotes around unescaped variables.

`./zsh-escape.zsh fix [OPTION]... [FILE]...`

Be careful if editing a file in place. It is recommended that you create a backup of the file first or commit it to source control.

#### Options

Option | Value | Description
------ | ----- | -----------
`-d` `--debug` |  | Includes debugging output. Only use this to debug issues, it is better suited to the `report` command instead.
`-i` `--in-place` |  | This will cause the file to be edited in place.
`-o` `--output` | `<file>` | Writes the output to a file. Only applicable if there is a single input file.

#### Example

```zsh
zsh-escape.zsh fix C:\source\antigen\bin\antigen.zsh
```
```text
...
# While boot.zsh is part of the ext/cache functionallity it may be disabled
# with ANTIGEN_CACHE flag, and it's always compiled with antigen.zsh
if [[ "$ANTIGEN_CACHE" != false ]]; then
...
```
