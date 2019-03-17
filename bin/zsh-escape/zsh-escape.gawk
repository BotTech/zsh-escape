BEGIN {
  strong = 0
  weak = 0
  # The character classes don't seem to work properly.
}
function print_debug(line) {
  if (debug) {
    print "DEBUG:",line
  }
}
function report_debug(line) {
  if (report) {
    print_debug(line)
  }
}
function report_error(line) {
  if (report) {
    print "ERROR:",line
  }
}
function report_print(line) {
  if (report) {
    print line
  }
}
function fix_print(char) {
  if (fix) {
    printf "%s",char
  }
}
{
  if (report) {
    print FNR,":",$0
    if (weak) {
      print_debug("Multi-line weak quote")
    } else if (strong) {
      print_debug("Multi-line strong quote")
    }
  }
}
/[$]/ {
  split($0, chars, "")
  comment = 0
  escape = 1
  unescaped = 0
  for (i = 0; i < length(chars); i++) {
    c = chars[i]
    if (escape) {
      escape = 0
      fix_print(c)
    } else if (comment) {
      fix_print(c)
    } else {
      switch (c) {
      case "'":
        if (strong) {
          # FIXME: '''' is a single quoted quote
          strong = 0
          report_debug("Strong quote ended")
        } else if (!weak) {
          strong = 1
          report_debug("Strong quote started")
        }
        fix_print(c)
        break
      case "\"":
        if (weak) {
          weak = 0
          report_debug("Weak quote ended")
        } else if (!strong) {
          weak = 1
          report_debug("Weak quote started")
        }
        fix_print(c)
        break
      case "\\":
        # It is a bit vague but it looks like escapes are valid outside of quotes too.
        if (i < length(chars) - 1) {
          escape = 1
        }
        fix_print(c)
        break
      case "$":
        # FIXME: $'abc' is valid
        # FIXME: if [[ "$foo" =~ ^abc$ ]]; then is valid
        if (!weak && !strong) {
          tail = substr($0, i)
          # FIXME: Add support for:
          #  ${name/pattern/repl}
          #  ${name//pattern/repl}
          #  ${name:/pattern/repl}
          #  ${name:offset}
          #  ${name:offset:length}
          # See http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion
          where = match(tail, /\$([*@#?$!_]|[+#^=~]?[a-zA-Z0-9_]*|[a-zA-Z0-9_]*([-+=?#%:]|:[-+=?#|*^]|::=|##|%%|:^^)[a-zA-Z0-9_]*|\{.*}|\(.*\))/)
          if (where) {
            var = substr(tail, RSTART, RLENGTH)
            i = i + RLENGTH - 1
            if (report) {
              # TODO: How can we make a function with varargs?
              print "- Unescaped variable:",var
            }
            fix_print("\"" var "\"")
          } else {
            report_error("Cannot retrieve the unescaped variable")
            report_debug(tail)
            fix_print(c)
          }
          unescaped++
        } else {
          fix_print(c)
        }
        break
      case "#":
        if (!weak && !strong) {
          comment = 1
        }
        fix_print(c)
        break
      default:
        fix_print(c)
        break
      }
    }
  }
  if (unescaped) {
    report_print("- Found an unescaped variable")
  } else {
    report_print("- All variables are escaped (or are not variables)")
  }
  if (escape) {
    report_debug("Found an invalid escape sequence")
  }
  fix_print("\n")
}
/^[^$]*$/ {
  if (fix) {
    print $0
  }
}
END {
  if (weak) {
    report_print("* Found an unclosed weak quote")
  } else if (strong) {
    report_print("* Found an unclosed strong quote")
  }
}
