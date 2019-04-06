# Tests

## Arrays

### Arrays must be escaped

```sh
$ cat unescaped-array-simple.zsh
| echo $commands[git]
$ zsh-escape.zsh report unescaped-array-simple.zsh
| 1 : echo $commands[git]
| - Unescaped variable: $commands[git]
| - Found an unescaped variable
```
