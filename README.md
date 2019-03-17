# Zsh Escape

Zsh Escape is a Zsh script for finding and automatically fixing unescaped variables in Zsh scripts.

## Prerequisites

* zsh
* gawk

## Installation

TODO

## Usage

### Report

It can be helpful to run the `report` command first.
This will go through each line in a file and print the line number followed by any potential errors.

`zsh-escape.zsh report [OPTION]... [FILE]...`

#### Options

Option | Value | Description
------ | ----- | -----------
`-d` `--debug` |  | Includes debugging output.
`-o` `--output` | `<file>` | Writes the output to a file.

#### Example

```sh
$ cat unescaped-test-simple.zsh
| if [[ $FOO == false ]]; then
|   echo "FALSE"
| fi
$ zsh-escape.zsh report unescaped-test-simple.zsh
| 1 : if [[ $FOO == false ]]; then
| - Unescaped variable: $FOO
| - Found an unescaped variable
| 2 :   echo "FALSE"
| 3 : fi
```

This shows that it found an unescaped variable `$FOO`.

### Fix

The `fix` command will automatically add missing quotes around unescaped variables.

`zsh-escape.zsh fix [OPTION]... [FILE]...`

Be careful if editing a file in place. It is recommended that you create a backup of the file first or commit it to source control.

#### Options

Option | Value | Description
------ | ----- | -----------
`-d` `--debug` |  | Includes debugging output. Only use this to debug issues, it is better suited to the `report` command instead.
`-i` `--in-place` |  | This will cause the file to be edited in place.
`-o` `--output` | `<file>` | Writes the output to a file. Only applicable if there is a single input file.

#### Example

```sh
$ cat unescaped-test-simple.zsh
| if [[ $FOO == false ]]; then
|   echo "FALSE"
| fi
$ zsh-escape.zsh fix unescaped-test-simple.zsh
| if [[ "$FOO" == false ]]; then
|   echo "FALSE"
| fi
```
