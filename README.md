# SwiftFormatLite

SwiftFormatLite is the in-memory subset of SwiftFormat. Its public formatter
API accepts Swift source as a `String` and returns a `String`; it has no file,
URL, CLI, lint, plugin, or directory-traversal API.

It retains the PrettyPrint pipeline and 25 formatter rewrite rules. Pure lint
rules, Markdown support, the CLI, plugins, generators, and instruction counters
are not included.

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
