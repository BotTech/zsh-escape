BEGIN {
  strong = 0
  weak = 0
  math = 0
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
    } else if (strong) {
      switch (c) {
      case "'":
        # FIXME: '''' is a single quoted quote
        strong = 0
        report_debug("Strong quote ended")
        break
      case "\\":
        if (i < length(chars) - 1) {
          escape = 1
        } else {
          # A continuation
        }
        break
      }
      fix_print(c)
    } else if (weak) {
      switch (c) {
      case "\"":
        weak = 0
        report_debug("Weak quote ended")
        break
      case "\\":
        if (i < length(chars) - 1) {
          escape = 1
        } else {
          # A continuation
        }
        break
      }
      fix_print(c)
    } else if (math) {
      switch (c) {
      case ")":
        if (i < length(chars) -1 && chars[i + 1] == ")") {
          i++
          math--
          report_debug("Arithmetic evaluation ended")
        }
        break
      }
      fix_print(c)
    } else {
      switch (c) {
      case "'":
        strong = 1
        report_debug("Strong quote started")
        fix_print(c)
        break
      case "\"":
        weak = 1
        report_debug("Weak quote started")
        fix_print(c)
        break
      case "\\":
        # The documentation is a bit vague but it looks like escapes are valid outside of quotes too.
        if (i < length(chars) - 1) {
          escape = 1
        }
        fix_print(c)
        break
      case "(":
        if (i < length(chars) -1 && chars[i + 1] == "(") {
          i++
          math++
          report_debug("Arithmetic evaluation started")
        } else {
          # Start of a subshell.
        }
        break
      case "$":
        tail = substr($0, i)
        arithmetic_expansion = match(tail, /^\$\(\((\)?[^)]+)*\)\)/)
        if (arithmetic_expansion) {
          expansion = substr(tail, RSTART, RLENGTH)
          i = i + RLENGTH - 1
          report_print("- Unescaped arithmetic expansion: " expansion)
          fix_print("\"" expansion "\"")
          unescaped++
          break
        }
        subshell_expansion = match(tail, /^\$\([^)]*\)/)
        if (subshell_expansion) {
          expansion = substr(tail, RSTART, RLENGTH)
          i = i + RLENGTH - 1
          report_print("- Unescaped subshell expansion: " expansion)
          fix_print("\"" expansion "\"")
          unescaped++
          break
        }
        # FIXME: $'abc' is valid
        # FIXME: if [[ "$foo" =~ ^abc$ ]]; then is valid
        # FIXME: Add support for:
        #  ${name/pattern/repl}
        #  ${name//pattern/repl}
        #  ${name:/pattern/repl}
        #  ${name:offset}
        #  ${name:offset:length}
        # FIXME: Add better array support. They are quite complicated.
        # See http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion
        parameter_expansion = match(tail, /^\$([*@#?$!_]|[+#^=~]?[a-zA-Z0-9_]+(\[[^]]*\])?|[a-zA-Z0-9_]*([-+=?#%:]|:[-+=?#|*^]|::=|##|%%|:^^)[a-zA-Z0-9_]*|\{.*})/)
        if (parameter_expansion) {
          expansion = substr(tail, RSTART, RLENGTH)
          i = i + RLENGTH - 1
          report_print("- Unescaped parameter expansion: " expansion)
          fix_print("\"" expansion "\"")
        } else {
          report_error("Cannot retrieve the unescaped expansion")
          report_debug(tail)
          fix_print(c)
        }
        unescaped++
        break
      case "#":
        comment = 1
        fix_print(c)
        break
      default:
        fix_print(c)
        break
      }
    }
  }
  if (unescaped) {
    report_print("- Found " unescaped " unescaped expansion" ((unescaped > 1) ? "s" : ""))
  } else {
    report_print("- All expansions are escaped")
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
  } else if (math) {
    report_print("* Found an unclosed arithmetic evaluation")
  }
}
