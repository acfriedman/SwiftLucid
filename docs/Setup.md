# Setup

A codebase that predates its house style has findings nobody will fix at once, so SwiftLucid's hooks
judge a change rather than the whole codebase. New and touched code answers to the style, and the rest is
left alone until someone works on it.

## Git pre-commit hook

```bash
#!/bin/sh
# .git/hooks/pre-commit: lint the doc comments this commit adds or changes
export PATH="$HOME/.mint/bin:$PATH"   # Git apps run hooks without your shell's PATH
if command -v swiftlucid >/dev/null 2>&1; then
  exec swiftlucid --staged .
fi
echo "warning: swiftlucid is not installed, so this commit's docs were not linted" >&2
```

Save it as `.git/hooks/pre-commit` and `chmod +x` it. `--staged` judges what the commit holds, not edits
left unstaged, and `git commit --no-verify` skips the hook.

**For a team,** commit the script as `.githooks/pre-commit` instead, and have each clone run
`git config core.hooksPath .githooks` once. To run a version pinned in the repository
([Installation](Installation.md)), make the hook's command
`exec swift run --quiet -c release --package-path BuildTools swiftlucid --staged .`, or
`exec mint run swiftlucid --staged .` with a `Mintfile`.

## The pre-commit framework

With [pre-commit](https://pre-commit.com), add SwiftLucid to `.pre-commit-config.yaml`; it builds the
tagged version itself:

```yaml
repos:
  - repo: https://github.com/acfriedman/SwiftLucid
    rev: 0.2.0
    hooks:
      - id: swiftlucid
```

## Xcode build phase

Add a Run Script phase after Compile Sources, so Xcode shows findings on what you have changed since the
last commit as you build. With the version pinned in `BuildTools`:

```bash
cd "$SRCROOT"
SDKROOT=$(xcrun --sdk macosx --show-sdk-path) \
  swift run --quiet -c release --package-path BuildTools swiftlucid --since HEAD "$SRCROOT"
```

`SDKROOT` builds the tool for the Mac even in an iOS target. With a local install instead:

```bash
cd "$SRCROOT"
export PATH="$HOME/.mint/bin:$PATH"
if command -v swiftlucid >/dev/null 2>&1; then
  swiftlucid --since HEAD "$SRCROOT"
else
  echo "warning: swiftlucid is not installed; see https://github.com/acfriedman/SwiftLucid#get-started"
fi
```

- **Xcode 15 and later** sandbox scripts, which stops SwiftLucid reading the sources and git. Set
  **User Script Sandboxing** (`ENABLE_USER_SCRIPT_SANDBOXING`) to **No** for the target.
- Uncheck **Based on dependency analysis**, so the phase runs on every build.
- An error fails the build. While a team brings the style in, `"severity": "warning"` in
  `.swiftlucid.json` shows findings without failing anything ([Configuration](Configuration.md)).
- To show every finding rather than a change's, drop `--since HEAD`.

## CI

`swiftlucid --since origin/main .` judges a branch the same way, after a checkout that fetches the
history back to the base, such as `fetch-depth: 0` in GitHub Actions.
