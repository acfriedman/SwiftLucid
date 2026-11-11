# LucidLint

Checks doc comments and module pages against a project's house style. It reports each fix in compiler format, so Xcode, CI, and a commit hook show it as is.

## Overview

``Linter`` runs ``Rules`` over a reading and reports each ``Diagnostic`` at the level the project's ``HouseStyle`` sets. ``Assessment`` is what a tool that shows the docs takes from it: whether each declaration owes a doc, and what the rules found.

## Topics

### Linting

- ``Linter``
- ``Rules``
- ``Rule``
- ``Diagnostic``
- ``Assessment``

### The house style

- ``HouseStyle``

### A change's findings

- ``ChangedFindings``

### Reading prose

- ``Sentences``
- ``SymbolReference``
