# SwiftFormatLite

SwiftFormatLite is the in-memory subset of SwiftFormat. Its public formatter
API accepts Swift source as a `String` and returns a `String`; it has no file,
URL, CLI, lint, plugin, or directory-traversal API.

The imported implementation keeps the upstream `Sources/SwiftFormat/API`,
`Core`, `PrettyPrint`, and `Rules` topology. The 25 formatter rewrite rules are
listed in `Maintenance/rules.txt`. Pure lint rules, Markdown support, the CLI,
plugins, generators, and instruction counters are not imported.

## Usage

```swift
import SwiftFormat

let formatter = SwiftFormatter()
let formatted = try formatter.format("let value=1")
```

Configuration can be provided as a value or decoded directly from an in-memory
JSON string:

```swift
var configuration = Configuration()
configuration.lineLength = 120

let configured = SwiftFormatter(configuration: configuration)
let decoded = try SwiftFormatter(configurationJSON: #"{"lineLength":120}"#)
```

Neither form reads configuration or source files.

## Upstream maintenance

Ownership is explicit:

- A: unchanged files listed in the A section of `Maintenance/files.txt` and
  restored from the exact upstream revision in `Upstream.lock`.
- B: Lite-owned `Package.swift`, public `SwiftFormatter`, documentation, and
  maintenance metadata.
- C: the transformed files in the C section of `Maintenance/files.txt`, plus
  generated rule files. The transformations are applied by
  `Maintenance/sync-upstream` and fail if their expected source shape changes.

To reproduce the imported tree:

```sh
Maintenance/sync-upstream
```
