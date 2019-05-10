# Tests

## Parameter Expansion

### Array parameter expansion must be escaped
```sh
$ zsh-escape.zsh report parameter-expansion-array.zsh
| 1: echo $commands[git]
| - Unescaped parameter expansion: $commands[git]
| - Found 1 unescaped expansion
$ zsh-escape.zsh fix parameter-expansion-array.zsh
| echo "$commands[git]"
```

## Arithmetic Expansion

### Arithmetic expansion must be escaped
```sh
$ zsh-escape.zsh report arithmetic-expansion.zsh
| 1: i=1 && echo $(( $i + 1 ))
| - Unescaped arithmetic expansion: $(( $i + 1 ))
| - Found 1 unescaped expansion
$ zsh-escape.zsh fix arithmetic-expansion.zsh
| i=1 && echo "$(( $i + 1 ))"
```

## Arithmetic Evaluation

### Arithmetic evaluation must not be escaped
```sh
$ zsh-escape.zsh report arithmetic-evaluation.zsh
| 1: i=0 && if (( $i + 1 )); then echo true; else echo false; fi
| - All expansions are escaped
$ zsh-escape.zsh fix arithmetic-evaluation.zsh
| i=0 && if (( $i + 1 )); then echo true; else echo false; fi
```

## Command Substitution

### Nested parentheses must not end the command substitution prematurely
```sh
$ zsh-escape.zsh report command-substitution-nested-parentheses.zsh
| 1: foo=$(print ${(qq)bar})
| - Unescaped command substitution: $(( $i + 1 ))
| - Found 1 unescaped expansion
$ zsh-escape.zsh fix command-substitution-nested-parentheses.zsh
| foo="$(print ${(qq)bar})"
```
