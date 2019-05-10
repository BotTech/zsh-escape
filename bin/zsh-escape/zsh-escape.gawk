BEGIN {
  STATE_NORMAL = 0
  STATE_ESCAPE = 1
  STATE_COMMENT = 2
  STATE_WEAK = 3
  STATE_STRONG = 4
  STATE_ARITHMETIC_EVALUATION = 5
  STATE_SUBSHELL = 6
  STATE_EXPANSION = 7
  STATE_PARAMETER_EXPANSION = 8
  STATE_COMMAND_SUBSTITUTION = 9
  STATE_ARITHMETIC_EXPANSION = 10
  STATE_ARITHMETIC_EXPANSION_SQUARE = 11
  STATE_UNBRACED_EXPANSION = 12
  STATE_SUBSCRIPT_EXPANSION = 13
  states_pos = 0
  states_push(STATE_NORMAL)
}
function states_push(val) {
  states[states_pos++] = val;
}
function states_peek() {
  if (states_pos == 0) {
    report_error("No more states remaining.")
    exit 1
  }
  return states[states_pos - 1]
}
function states_peek2() {
  if (states_size <= 1) {
    return states_peek()
  }
  return states[states_pos - 2]
}
function states_pop() {
  if (states_pos < 1) {
    report_error("No more states remaining.")
    exit 1
  }
  return states[--states_pos]
}
function states_replace(next_state) {
  states_pop()
  states_push(next_state)
}
function print_debug(line) {
  if (debug) {
    print("DEBUG: " line)
  }
}
function report_debug(line) {
  if (report) {
    print_debug(line)
  }
}
function report_error(line) {
  if (report) {
    print("ERROR: " line)
  }
}
function report_print(line) {
  if (report) {
    print(line)
  }
}
function fix_print(c) {
  if (fix) {
    printf("%s", c)
  }
}
function handle_double_quote() {
  states_push(STATE_WEAK)
  report_debug("Weak quote started.")
  fix_print(c)
}
function handle_single_quote() {
  states_push(STATE_STRONG)
  report_debug("Strong quote started.")
  fix_print(c)
}
function handle_parenthesis(escape) {
  if (substr($0, i, 2) == "((") {
    i++
    states_push(STATE_ARITHMETIC_EVALUATION)
    report_debug("Arithmetic evaluation started.")
    fix_print("((")
  } else {
    # FIXME: This could be an array assignment.
    states_push(STATE_SUBSHELL)
    report_debug("Subshell started.")
    report_print("- Found unescaped subshell.")
    if (escape) {
      fix_print("\"")
    }
    fix_print(c)
  }
}
function handle_dollar(escape) {
  states_push(STATE_EXPANSION)
  if (escape) {
    fix_print("\"")
  }
  fix_print(c)
}
function handle_hash() {
  states_push(STATE_COMMENT)
  report_debug("Comment started.")
  fix_print(c)
}
function end_escape() {
  print("TODO")
}
{
  report_print(FNR ": " $0)
  split($0, chars, "")
  continuation = 0
  for (i = 0; i < length(chars); i++) {
    c = chars[i]
    state = states_peek()
    if (state != STATE_ESCAPE && c == "\\") {
      # An escape at the end of the line does nothing except that then next line continues the previous line.
      # http://zsh.sourceforge.net/Doc/Release/Shell-Grammar.html#Quoting
      if (i == length(chars) - 1) {
        continuation = 1
      } else {
        states_push(STATE_ESCAPE)
      }
    } else {
      switch (state) {
      case 0: # STATE_NORMAL
        # TODO: Most of these checks also have to apply to other states.
        switch (c) {
        case "\"":
          handle_double_quote()
          break
        case "'":
          handle_single_quote()
          break
        case "(":
          handle_parenthesis(1)
          break
        case "$":
          handle_dollar(1)
          break
        case "#":
          handle_hash()
          break
        default:
          fix_print(c)
          break
        }
        break
      case 1: # STATE_ESCAPE
        states_pop()
        report_debug("Escaped: " c ".")
        fix_print(c)
        break
      case 2: # STATE_COMMENT
        fix_print(c)
        break
      case 3: # STATE_WEAK
        switch (c) {
        case "\"":
          states_pop()
          report_debug("Weak quote ended.")
          break
        case "$":
          handle_dollar(0)
          break
        }
        fix_print(c)
        break
      case 4: # STATE_STRONG
        if (c == "'") {
          # FIXME: '''' is a single quoted quote.
          states_pop()
          report_debug("Strong quote ended.")
        }
        fix_print(c)
        break
      case 5: # STATE_ARITHMETIC_EVALUATION
        if (substr($0, i, 2) == "))") {
          i++
          states_pop()
          report_debug("Arithmetic evaluation ended.")
          fix_print("))")
        } else {
          switch (c) {
          case "$":
            # Don't escape inside of arithmetic evaluation.
            handle_dollar(0)
            break
          case "(":
            handle_parenthesis(0)
            break
          }
        }
        break
      case 6: # STATE_SUBSHELL
        switch (c) {
        case ")":
          states_pop()
          report_debug("Subshell ended.")
          break
        case "\"":
          handle_double_quote()
          break
        case "'":
          handle_single_quote()
          break
        case "(":
          handle_parenthesis(1)
          break
        case "$":
          handle_dollar(1)
          break
        case "#":
          handle_hash()
          break
        default:
          fix_print(c)
          break
        }
        break
      case 7: # STATE_EXPANSION
        switch (c) {
        case "{":
          states_replace(STATE_PARAMETER_EXPANSION)
          report_debug("Parameter expansion started.")
          report_print("- Found unescaped parameter expansion.")
          fix_print(c)
          break
        case "(":
          if (substr($0, i, 2) == "((") {
            states_replace(STATE_ARITHMETIC_EXPANSION)
            report_debug("Arithmetic expansion started.")
            report_print("- Found unescaped arithmetic expansion.")
          } else {
            states_replace(STATE_COMMAND_SUBSTITUTION)
            report_debug("Command substitution started.")
            report_print("- Found unescaped command substitution.")
          }
          fix_print(c)
          break
        case "[":
          states_replace(STATE_ARITHMETIC_EXPANSION_SQUARE)
          report_debug("Arithmetic expansion started.")
          report_print("- Found unescaped arithmetic expansion.")
          fix_print(c)
          break
        case /[^=~#+*@?\-$!a-zA-Z0-9_]/:
          states_replace(STATE_UNBRACED_EXPANSION)
          report_debug("Unbraced expansion started.")
          report_print("- Found unescaped unbraced expansion.")
          fix_print(c)
          break
        default:
          report_debug("Expansion ended.")
          # FIXME: This may already be escaped.
          fix_print("\"" c)
          break
        }
        break
      case 8: # STATE_PARAMETER_EXPANSION
        if (c == "}") {
          states_pop()
          report_debug("Parameter expansion ended.")
          # TODO: Escape if not escaped.
        }
        # TODO: Other normal states
        fix_print(c)
        break
      case 9: # STATE_COMMAND_SUBSTITUTION
        if (c == ")") {
          states_pop()
          report_debug("Command substitution ended.")
          # TODO: Escape if not escaped.
        }
        # TODO: Other normal states
        fix_print(c)
        break
      case 10: # STATE_ARITHMETIC_EXPANSION
        if (substr($0, i, 2) == "))") {
          i++
          states_pop()
          report_debug("Arithmetic expansion ended.")
          fix_print("))")
        } else {
          # TODO: Other normal states
          fix_print(c)
        }
        break
      case 11: # STATE_ARITHMETIC_EXPANSION_SQUARE
        if (c == "]") {
          states_pop()
          report_debug("Arithmetic expansion ended.")
        }
        # TODO: Other normal states
        fix_print(c)
        break
      case 12: # STATE_UNBRACED_EXPANSION
        switch (c) {
        # FIXME: We should only allow a single character from: # ‘*’, ‘@’, ‘#’, ‘?’, ‘-’, ‘$’, or ‘!’.
        # http://zsh.sourceforge.net/Doc/Release/Parameters.html
        case /[^=~#+*@?\-$!a-zA-Z0-9_]/:
          fix_print(c)
          break
        case "[":
          states_replace(STATE_SUBSCRIPT_EXPANSION)
          report_debug("Unbraced subscript started.")
          report_print("- Found unescaped subscript expansion.")
          fix_print(c)
          break
        default:
          states_pop()
          fix_print(c)
          # TODO: Escape if not escaped already.
          break
        }
        break
      case 13: # STATE_SUBSCRIPT_EXPANSION
        # TODO: Apply all the normal checks.
        # TODO: If ] then it ends. Escape if not escaped.
        break
      default:
        fix_print(c)
        report_error("Unsupported state: " state ".")
        break
      }
    }
  }
  fix_print("\n")
  if (!continuation) {
    switch (state) {
    case 2: # STATE_COMMENT
      states_pop()
      report_debug("Comment ended.")
      break
    case 7: # STATE_EXPANSION
      states_pop()
      report_debug("Unknown expansion reached the end of the line.")
      break
    }
  }
}
END {
  for (i = 0; i < states_pos; i++) {
    state = states[i]
    switch (state) {
    case 0: # STATE_NORMAL
      # Ignore.
      break
    case 1: # STATE_ESCAPE
      # Ignore.
      break
    case 2: # STATE_COMMENT
      # Ignore.
      break
    case 3: # STATE_WEAK
      report_print("* Unclosed weak quotes. Expected \".")
      break
    case 4: # STATE_STRONG
      report_print("* Unclosed strong quotes. Expected '.")
      break
    case 5: # STATE_ARITHMETIC_EVALUATION
      report_print("* Unclosed arithmetic evaluation. Expected )).")
      break
    case 6: # STATE_SUBSHELL
      report_print("* Unclosed subshell. Expected ).")
      break
    case 7: # STATE_EXPANSION
      # Ignore.
      break
    case 8: # STATE_PARAMETER_EXPANSION
      report_print("* Unclosed parameter expansion. Expected }.")
      break
    case 9: # STATE_COMMAND_SUBSTITUTION
      report_print("* Unclosed command substitution. Expected ).")
      break
    case 10: # STATE_ARITHMETIC_EXPANSION
      report_print("* Unclosed arithmetic expansion. Expected )).")
      break
    case 11: # STATE_ARITHMETIC_EXPANSION_SQUARE
      report_print("* Unclosed arithmetic expansion. Expected ].")
      break
    default:
      report_print("* Unknown remaining state: " state)
      break
    }
  }
}
