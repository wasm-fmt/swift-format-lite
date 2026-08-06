# Upstream maintenance

Source ownership is explicit:

- A: unchanged files in `upstream-files.txt`, imported byte-for-byte from the
  exact upstream revision in `../Upstream.lock`.
- B: Lite-owned sources in `lite-sources.txt`, plus `../Package.swift`,
  documentation, and maintenance metadata.
- C: upstream-derived files changed for Lite. Mechanical files are listed in
  `transformed-sources.txt`; the importer requires exactly one standalone
  `import Foundation` and removes it deterministically. Manually maintained
  snapshots are listed in `adapted-sources.lock`; each records the exact
  upstream blob that was reviewed. A changed blob stops synchronization until
  its semantic changes are ported manually and the lock is deliberately
  updated.
- Generated: the pipeline, rule registry, and rule-name cache derived from
  `rules.txt`.

Tests follow the same manual-snapshot model as C sources. They are never
rewritten by a synchronization command; `test-sources.lock` binds every
converted Swift Testing file to its reviewed upstream blob. The package does
not vendor `swift-testing`, and no Lite-specific test cases are added.

The maintenance implementation is a separate Swift package under `Tools`; it
does not add products or dependencies to the library package. Its
responsibilities remain available as separate commands:

```sh
Maintenance/import-upstream --output /tmp/swift-format-lite-candidate
Maintenance/generate-rules --output /tmp/swift-format-lite-candidate
Maintenance/audit --candidate /tmp/swift-format-lite-candidate
```

`Maintenance/sync-upstream` only orchestrates those stages. It constructs a
complete candidate tree, audits it before installation, replaces only the
explicitly managed paths, and rolls back if the installed-tree audit fails.

After changing an exact upstream tag or SHA, first run the individual commands
to inspect the candidate. Review any changed adapted-source or test blobs,
manually port accepted semantic changes, update their exact locks, then run:

```sh
Maintenance/sync-upstream
```

`../Upstream.lock` records the exact Swift toolchain and both the SwiftFormat
and SwiftSyntax tag/SHA pairs. `../Package.swift` must use the locked stable
SwiftSyntax version; branch and revision dependencies are rejected so that
SwiftFormatLite can itself be published as a stable Semantic Version.

The library source audit also enforces the WASM size boundary at its source:
only the in-memory configuration API may conditionally fall back to
`Foundation`; WASI builds import `FoundationEssentials`, and CharacterSet-based
string operations are forbidden.
