# swiftlucid

The command line: it lints every path it is given, or only what a change touched. Its findings print in compiler format, so Xcode, CI, and a commit hook use them as is.

## Overview

The lint reads the whole of each path and reports every finding, or, with `--staged` and `--since`, only those on what a change touched, through ``ChangeLint``. Only errors fail the run, so a house style can bring a rule in as a warning first.

## Topics

### Commands

- ``ChangeLint``
