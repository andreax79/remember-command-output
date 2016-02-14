# remember-command-output
Remember the output of a command and execute commands on the lines

```
Usage: ./ro.sh [-l] COMMAND [arg ...]
       ./ro.sh [-l] RANGE [COMMAND arg ...]

Options:
  -l, --lines           Output the line number, starting at line 1
  RANGE                 Comma-separated list of line number or ranges

Examples:

  Execute the grep command and store the output
      ./ro.sh grep -r test .

  Display the output of the last command, adding line numbers
      ./ro.sh -l

  Open the files at lines 2-4 and 5 in the output of the last command with vi
      ./ro.sh 2-4,5 vi
```

