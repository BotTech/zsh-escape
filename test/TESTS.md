# Tests

## Arrays

### Array expansion must be escaped

```sh
$ zsh-escape.zsh report unescaped-array-simple.zsh
| 1 : echo $commands[git]
| - Unescaped parameter expansion: $commands[git]
| - Found 1 unescaped expansion
```

## Arithmetic Evaluation

### Arithmetic expansion must be escaped

```sh
$ zsh-escape.zsh report escape-arithmetic-expansion.zsh
| 1 : i=1 && echo $(( $i + 1 ))
| - Unescaped arithmetic expansion: $(( $i + 1 ))
| - Found 1 unescaped expansion
```

### Arithmetic evaluation must not be escaped

```sh
$ zsh-escape.zsh report exclude-arithmetic-evaluation.zsh
| 1 : i=0 && if (( $i + 1 )); then echo true; else echo false; fi
| - All expansions are escaped
```
