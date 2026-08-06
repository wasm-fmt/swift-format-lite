# SwiftFormatLite

SwiftFormatLite is the in-memory subset of SwiftFormat. Its public formatter
API accepts Swift source as a `String` and returns a `String`; it has no file,
URL, CLI, lint, plugin, or directory-traversal API.

The imported implementation keeps the upstream `Sources/SwiftFormat/API`,
`Core`, `PrettyPrint`, and `Rules` topology. The 25 formatter rewrite rules are
listed in `Maintenance/rules.txt`. Pure lint rules, Markdown support, the CLI,
plugins, generators, and instruction counters are not imported.

Tests for the retained API, Core, PrettyPrint implementation, and formatter
rules are manually migrated from their upstream XCTest sources to Swift
Testing. `Maintenance/test-sources.lock` records the exact reviewed upstream
blob for every converted suite and support file. The converted sources do not
import XCTest, the package does not vendor `swift-testing`, and no
Lite-specific test cases are added.

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

- A: unchanged files in `Maintenance/upstream-files.txt`, imported byte-for-byte
  from the exact upstream revision in `Upstream.lock`.
- B: Lite-owned sources in `Maintenance/lite-sources.txt`, plus `Package.swift`,
  documentation, and maintenance metadata.
- C: manually maintained source snapshots in
  `Maintenance/adapted-sources.lock`. Each snapshot records the exact upstream
  blob that was reviewed. A changed blob stops synchronization until its
  semantic changes are ported manually and the lock is deliberately updated.
- Generated: the pipeline, rule registry, and rule-name cache derived from
  `Maintenance/rules.txt`.

Tests follow the same manual-snapshot model as C sources. They are never
rewritten by a synchronization command; `Maintenance/test-sources.lock` binds
each converted Swift Testing file to its reviewed upstream blob.

The maintenance implementation is a separate Swift package under
`Maintenance/Tools`; it does not add products or dependencies to the library
package. Its responsibilities remain available as separate commands:

```sh
Maintenance/import-upstream --output /tmp/swift-format-lite-candidate
Maintenance/generate-rules --output /tmp/swift-format-lite-candidate
Maintenance/audit --candidate /tmp/swift-format-lite-candidate
```

`Maintenance/sync-upstream` only orchestrates those stages. It constructs a
complete candidate tree, audits it before installation, replaces only the
explicitly managed paths, and rolls back if the installed-tree audit fails.
There are no regex-based source transformations.

After changing an exact upstream tag or SHA, first run the individual commands
to inspect the candidate. Review any changed adapted-source or test blobs,
manually port accepted semantic changes, update their exact locks, then run:

```sh
Maintenance/sync-upstream
```

The exact Swift toolchain is recorded in `Upstream.lock`. With that toolchain
active, build and run the migrated tests using:

```sh
swift test
```
