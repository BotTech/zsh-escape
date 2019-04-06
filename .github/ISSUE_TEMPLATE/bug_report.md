---
name: Bug report
about: Create a report to help us improve
labels: bug

---

**Description**

A clear and concise description of what the bug is.

**Versions**

Component  | Version
---------- | -------
Zsh Escape | da39a3ee5e6b4b0d3255bfef95601890afd80709 (`git rev-parse HEAD`)
OS | Windows 10
Zsh | zsh 5.5.1 (i686-pc-cygwin) (`zsh --version`)

**Steps To Reproduce**

Steps to reproduce the bug:
1. Use the following file `bad-script.zsh`:
```zsh
dir=$1
cd $dir
```
2. Run:
```zsh
zsh-escape.zsh report bad-script.zsh
```

**Expected Behaviour**

A clear and concise description of what you expected to happen.

**Actual Behaviour**

A clear and concise description of what actually happened.

**Screenshots and/or Logs**

Add screenshots and/or logs to help explain your problem.

**Additional Context**

Add any other context about the problem here.
