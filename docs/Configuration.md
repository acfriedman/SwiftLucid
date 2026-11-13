# Configuration

The [rules](Rules.md) are SwiftLucid's own house style. A project picks its own in `.swiftlucid.json`,
which SwiftLucid reads from the current directory or the nearest folder above it; with none, every rule
is an error. Every key is optional:

```json
{
  "severity": "warning",
  "rules": { "missing-doc": "error", "summary-*": "off" },
  "exclude": ["Sources/Generated", "**/*.pb.swift"],
  "requireDocs": "public"
}
```

| Key | Does |
| --- | --- |
| `severity` | the level of every rule `rules` doesn't name: `error` (the default), `warning`, or `off` |
| `rules` | a level per rule code, or per prefix ending in `*`; a code wins over a prefix, and a longer prefix over a shorter one |
| `exclude` | paths not judged, from the folder holding `.swiftlucid.json`: `*`, `**`, `?`, or a folder for all of it; their declarations still resolve links |
| `requireDocs` | the narrowest access that owes a doc for `missing-doc`: `public`, `package`, or `internal` (the default) |

Warnings print as `warning:` and leave the exit status 0, so a team can bring a rule in before it gates
anything: start with `"severity": "warning"`, then raise rules to `error` as the code meets them. A key
or rule code SwiftLucid doesn't know stops the run, so a typo can't leave a rule on unnoticed.

`--style <file>` reads a style from elsewhere ([Usage](Usage.md)); its `exclude` paths start from the
folder that file is in.
