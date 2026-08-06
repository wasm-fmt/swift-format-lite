import Foundation

struct UpstreamLock {
  let swiftFormatTag: String
  let swiftFormatSHA: String
  let swiftSyntaxTag: String
  let swiftSyntaxSHA: String
  let swiftVersion: String
  let swiftToolsVersion: String

  static func load(from url: URL) throws -> UpstreamLock {
    let text = try FileSystem.readText(url)
    var values: [String: String] = [:]

    for line in nonCommentLines(in: text) {
      let pieces = line.split(separator: "=", maxSplits: 1).map {
        $0.trimmingCharacters(in: .whitespaces)
      }
      try require(pieces.count == 2, "invalid Upstream.lock entry: \(line)")
      let key = pieces[0]
      let quotedValue = pieces[1]
      try require(
        quotedValue.count >= 2
          && quotedValue.hasPrefix("\"")
          && quotedValue.hasSuffix("\""),
        "Upstream.lock value must be quoted: \(key)"
      )
      try require(values[key] == nil, "duplicate Upstream.lock key: \(key)")
      values[key] = String(quotedValue.dropFirst().dropLast())
    }

    let expectedKeys: Set<String> = [
      "swift-format.tag",
      "swift-format.sha",
      "swift-syntax.tag",
      "swift-syntax.sha",
      "swift.toolchain",
      "swift.tools-version",
    ]
    let actualKeys = Set(values.keys)
    try require(
      actualKeys == expectedKeys,
      "Upstream.lock keys differ; expected \(expectedKeys.sorted()), found \(actualKeys.sorted())"
    )

    let swiftFormatTag = try requiredValue("swift-format.tag", in: values)
    let swiftFormatSHA = try requiredValue("swift-format.sha", in: values)
    let swiftSyntaxTag = try requiredValue("swift-syntax.tag", in: values)
    let swiftSyntaxSHA = try requiredValue("swift-syntax.sha", in: values)
    let toolchain = try requiredValue("swift.toolchain", in: values)
    let swiftToolsVersion = try requiredValue("swift.tools-version", in: values)

    try require(isFullSHA(swiftFormatSHA), "invalid swift-format full SHA")
    try require(isFullSHA(swiftSyntaxSHA), "invalid swift-syntax full SHA")
    try require(!swiftFormatTag.isEmpty, "swift-format tag must not be empty")
    try require(!swiftSyntaxTag.isEmpty, "swift-syntax tag must not be empty")
    try require(
      toolchain.hasPrefix("Swift ") && toolchain.count > "Swift ".count,
      "swift.toolchain must have the form \"Swift <version>\""
    )
    try require(!swiftToolsVersion.isEmpty, "swift.tools-version must not be empty")

    return UpstreamLock(
      swiftFormatTag: swiftFormatTag,
      swiftFormatSHA: swiftFormatSHA,
      swiftSyntaxTag: swiftSyntaxTag,
      swiftSyntaxSHA: swiftSyntaxSHA,
      swiftVersion: String(toolchain.dropFirst("Swift ".count)),
      swiftToolsVersion: swiftToolsVersion
    )
  }

  private static func requiredValue(
    _ key: String,
    in values: [String: String]
  ) throws -> String {
    guard let value = values[key] else {
      throw MaintenanceError("missing Upstream.lock key: \(key)")
    }
    return value
  }
}

struct AdaptedSource {
  let destination: String
  let upstreamSource: String
  let upstreamBlob: String
}

enum TestSourceKind: String {
  case suite
  case support
}

struct TestSource {
  let kind: TestSourceKind
  let destination: String
  let upstreamSource: String
  let upstreamBlob: String
}

struct MaintenanceProject {
  static let generatedSourcePaths = [
    "Sources/SwiftFormat/Core/Pipelines+Generated.swift",
    "Sources/SwiftFormat/Core/RuleNameCache+Generated.swift",
    "Sources/SwiftFormat/Core/RuleRegistry+Generated.swift",
  ]

  let root: URL
  let lock: UpstreamLock
  let upstreamFiles: [String]
  let adaptedSources: [AdaptedSource]
  let liteSources: [String]
  let rules: [String]
  let testSources: [TestSource]

  var suiteSources: [TestSource] {
    testSources.filter { $0.kind == .suite }
  }

  var supportSources: [TestSource] {
    testSources.filter { $0.kind == .support }
  }

  static func load(root: URL) throws -> MaintenanceProject {
    let normalizedRoot = root.standardizedFileURL
    var isDirectory: ObjCBool = false
    try require(
      FileManager.default.fileExists(
        atPath: normalizedRoot.path,
        isDirectory: &isDirectory
      ) && isDirectory.boolValue,
      "project root does not exist: \(normalizedRoot.path)"
    )

    let lock = try UpstreamLock.load(
      from: normalizedRoot.appendingPathComponent("Upstream.lock")
    )
    let upstreamFiles = try loadPathManifest(
      normalizedRoot.appendingPathComponent("Maintenance/upstream-files.txt"),
      label: "upstream-files.txt"
    )
    let adaptedSources = try loadAdaptedSources(
      normalizedRoot.appendingPathComponent("Maintenance/adapted-sources.lock")
    )
    let liteSources = try loadPathManifest(
      normalizedRoot.appendingPathComponent("Maintenance/lite-sources.txt"),
      label: "lite-sources.txt"
    )
    let rules = try loadPathManifest(
      normalizedRoot.appendingPathComponent("Maintenance/rules.txt"),
      label: "rules.txt"
    )
    let testSources = try loadTestSources(
      normalizedRoot.appendingPathComponent("Maintenance/test-sources.lock")
    )

    let project = MaintenanceProject(
      root: normalizedRoot,
      lock: lock,
      upstreamFiles: upstreamFiles,
      adaptedSources: adaptedSources,
      liteSources: liteSources,
      rules: rules,
      testSources: testSources
    )
    try project.validate()
    return project
  }

  func gitData(specification: String) throws -> Data {
    try ProcessRunner.run(
      "git",
      arguments: ["show", specification],
      currentDirectory: root
    ).standardOutput
  }

  func gitText(specification: String) throws -> String {
    String(decoding: try gitData(specification: specification), as: UTF8.self)
  }

  func upstreamData(path: String) throws -> Data {
    try gitData(specification: "\(lock.swiftFormatSHA):\(path)")
  }

  func upstreamText(path: String) throws -> String {
    try gitText(specification: "\(lock.swiftFormatSHA):\(path)")
  }

  func upstreamBlob(path: String) throws -> String {
    try ProcessRunner.text(
      "git",
      arguments: ["rev-parse", "\(lock.swiftFormatSHA):\(path)"],
      currentDirectory: root
    ).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func blob(of file: URL) throws -> String {
    try ProcessRunner.text(
      "git",
      arguments: ["hash-object", file.path],
      currentDirectory: root
    ).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func validate() throws {
    try require(!upstreamFiles.isEmpty, "upstream-files.txt must not be empty")
    try require(!adaptedSources.isEmpty, "adapted-sources.lock must not be empty")
    try require(!liteSources.isEmpty, "lite-sources.txt must not be empty")
    try require(rules.count == 25, "rules.txt must contain exactly 25 rules")
    try require(suiteSources.count == 96, "test-sources.lock must contain exactly 96 suites")
    try require(supportSources.count == 5, "test-sources.lock must contain exactly 5 support files")

    try requireUnique(upstreamFiles, label: "upstream-files.txt paths")
    try requireUnique(adaptedSources.map(\.destination), label: "adapted destinations")
    try requireUnique(adaptedSources.map(\.upstreamSource), label: "adapted upstream sources")
    try requireUnique(liteSources, label: "lite-sources.txt paths")
    try requireUnique(rules, label: "formatter rules")
    try requireUnique(testSources.map(\.destination), label: "test destinations")
    try requireUnique(testSources.map(\.upstreamSource), label: "upstream test sources")

    for path in upstreamFiles {
      try validateLiteralPath(path, label: "upstream path")
      let allowed =
        path == ".gitignore"
        || path == "LICENSE.txt"
        || path.hasPrefix("Sources/SwiftFormat/")
      try require(allowed, "upstream path is outside the import area: \(path)")
    }
    try require(upstreamFiles.contains(".gitignore"), "upstream-files.txt must include .gitignore")
    try require(
      upstreamFiles.contains("LICENSE.txt"), "upstream-files.txt must include LICENSE.txt")

    for source in adaptedSources {
      try validateSourcePath(source.destination, label: "adapted destination")
      try validateSourcePath(source.upstreamSource, label: "adapted upstream source")
      try require(
        isFullSHA(source.upstreamBlob),
        "invalid adapted upstream blob for \(source.destination): \(source.upstreamBlob)"
      )
    }

    for path in liteSources {
      try validateSourcePath(path, label: "Lite-owned source")
    }

    for rule in rules {
      try require(isRuleName(rule), "invalid formatter rule name: \(rule)")
      let sourcePath = ruleSourcePath(rule)
      try require(
        upstreamFiles.contains(sourcePath),
        "formatter rule source is not A-owned: \(sourcePath)"
      )
    }

    for source in testSources {
      try validateTestDestination(source.destination)
      try validateTestUpstreamSource(source.upstreamSource)
      try require(
        isFullSHA(source.upstreamBlob),
        "invalid test upstream blob for \(source.destination): \(source.upstreamBlob)"
      )
      if source.kind == .suite {
        try require(
          !source.destination.localizedCaseInsensitiveContains("whitespace")
            && !source.destination.localizedCaseInsensitiveContains("lint")
            && !source.destination.localizedCaseInsensitiveContains("wasm"),
          "excluded test category is locked: \(source.destination)"
        )
      }
    }

    let aSources = Set(upstreamFiles.filter { $0.hasPrefix("Sources/SwiftFormat/") })
    let bSources = Set(liteSources)
    let cSources = Set(adaptedSources.map(\.destination))
    let generatedSources = Set(Self.generatedSourcePaths)
    try require(aSources.isDisjoint(with: bSources), "A and B source ownership overlaps")
    try require(aSources.isDisjoint(with: cSources), "A and C source ownership overlaps")
    try require(aSources.isDisjoint(with: generatedSources), "A and generated ownership overlaps")
    try require(bSources.isDisjoint(with: cSources), "B and C source ownership overlaps")
    try require(bSources.isDisjoint(with: generatedSources), "B and generated ownership overlaps")
    try require(cSources.isDisjoint(with: generatedSources), "C and generated ownership overlaps")
  }
}

func ruleSourcePath(_ rule: String) -> String {
  if rule == "NoEmptyLinesOpeningClosingBraces" {
    return "Sources/SwiftFormat/Rules/NoEmptyLineOpeningClosingBraces.swift"
  }
  return "Sources/SwiftFormat/Rules/\(rule).swift"
}

func ruleTestPath(_ rule: String) -> String {
  switch rule {
  case "NoEmptyLinesOpeningClosingBraces":
    return "Tests/SwiftFormatTests/Rules/NoEmptyLinesOpeningClosingBracesTests.swift"
  case "OmitExplicitReturns":
    return "Tests/SwiftFormatTests/Rules/OmitReturnsTests.swift"
  default:
    return "Tests/SwiftFormatTests/Rules/\(rule)Tests.swift"
  }
}

private func loadPathManifest(_ url: URL, label: String) throws -> [String] {
  let lines = nonCommentLines(in: try FileSystem.readText(url))
  try require(!lines.isEmpty, "\(label) must not be empty")
  return lines
}

private func loadAdaptedSources(_ url: URL) throws -> [AdaptedSource] {
  try nonCommentLines(in: FileSystem.readText(url)).map { line in
    let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
    try require(
      fields.count == 3,
      "adapted-sources.lock entry must have 3 fields: \(line)"
    )
    return AdaptedSource(
      destination: fields[0],
      upstreamSource: fields[1],
      upstreamBlob: fields[2]
    )
  }
}

private func loadTestSources(_ url: URL) throws -> [TestSource] {
  try nonCommentLines(in: FileSystem.readText(url)).map { line in
    let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
    try require(
      fields.count == 4,
      "test-sources.lock entry must have 4 fields: \(line)"
    )
    guard let kind = TestSourceKind(rawValue: fields[0]) else {
      throw MaintenanceError("invalid test source kind: \(fields[0])")
    }
    return TestSource(
      kind: kind,
      destination: fields[1],
      upstreamSource: fields[2],
      upstreamBlob: fields[3]
    )
  }
}

private func validateLiteralPath(_ path: String, label: String) throws {
  try require(!path.isEmpty, "\(label) must not be empty")
  try require(!path.hasPrefix("/"), "\(label) must be relative: \(path)")
  try require(!path.contains("\\"), "\(label) must use forward slashes: \(path)")
  try require(
    !path.contains("*") && !path.contains("?") && !path.contains("[") && !path.contains("]"),
    "\(label) must not contain glob syntax: \(path)"
  )

  let components = path.split(separator: "/", omittingEmptySubsequences: false)
  try require(
    components.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." },
    "\(label) is not a normalized literal path: \(path)"
  )
}

private func validateSourcePath(_ path: String, label: String) throws {
  try validateLiteralPath(path, label: label)
  try require(
    path.hasPrefix("Sources/SwiftFormat/"),
    "\(label) is outside Sources/SwiftFormat: \(path)"
  )
}

private func validateTestDestination(_ path: String) throws {
  try validateLiteralPath(path, label: "test destination")
  let prefixes = [
    "Tests/SwiftFormatTests/API/",
    "Tests/SwiftFormatTests/Core/",
    "Tests/SwiftFormatTests/PrettyPrint/",
    "Tests/SwiftFormatTests/Rules/",
    "Tests/SwiftFormatTests/Support/",
  ]
  try require(
    prefixes.contains(where: path.hasPrefix),
    "test destination is outside Tests/SwiftFormatTests: \(path)"
  )
}

private func validateTestUpstreamSource(_ path: String) throws {
  try validateLiteralPath(path, label: "upstream test source")
  let prefixes = [
    "Tests/SwiftFormatTests/API/",
    "Tests/SwiftFormatTests/Core/",
    "Tests/SwiftFormatTests/PrettyPrint/",
    "Tests/SwiftFormatTests/Rules/",
    "Sources/_SwiftFormatTestSupport/",
  ]
  try require(
    prefixes.contains(where: path.hasPrefix),
    "test source is outside reviewed upstream areas: \(path)"
  )
}

private func requireUnique(_ values: [String], label: String) throws {
  var seen: Set<String> = []
  var duplicates: Set<String> = []
  for value in values where !seen.insert(value).inserted {
    duplicates.insert(value)
  }
  try require(
    duplicates.isEmpty,
    "\(label) contain duplicates: \(duplicates.sorted().joined(separator: ", "))"
  )
}

private func isFullSHA(_ value: String) -> Bool {
  value.count == 40
    && value.allSatisfy { character in
      ("0"..."9").contains(character) || ("a"..."f").contains(character)
    }
}

private func isRuleName(_ value: String) -> Bool {
  guard let first = value.first, ("A"..."Z").contains(first) else {
    return false
  }
  return value.allSatisfy {
    ("A"..."Z").contains($0)
      || ("a"..."z").contains($0)
      || ("0"..."9").contains($0)
  }
}
