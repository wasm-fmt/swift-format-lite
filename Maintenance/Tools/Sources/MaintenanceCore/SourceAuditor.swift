import Foundation

struct SourceAuditResult {
  let sourceFileCount: Int
}

enum SourceAuditor {
  static func run(
    project: MaintenanceProject,
    candidateRoot: URL,
    generatedFiles: GeneratedRuleFiles
  ) throws -> SourceAuditResult {
    try verifyExactCandidateTree(project: project, candidateRoot: candidateRoot)
    try verifyExactSourceTree(project: project, candidateRoot: candidateRoot)
    try verifyUpstreamOwnedFiles(project: project, candidateRoot: candidateRoot)
    try verifyMechanicallyTransformedFiles(project: project, candidateRoot: candidateRoot)
    try verifyAdaptedAndLiteFiles(project: project, candidateRoot: candidateRoot)
    try verifyGeneratedFiles(candidateRoot: candidateRoot, generatedFiles: generatedFiles)
    try verifyRuleSources(project: project, candidateRoot: candidateRoot)
    try verifyFoundationIsolation(project: project, candidateRoot: candidateRoot)
    try verifyExcludedSourceFeatures(project: project, candidateRoot: candidateRoot)

    return SourceAuditResult(sourceFileCount: expectedSourcePaths(project).count)
  }

  private static func verifyExactCandidateTree(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    let candidate = candidateRoot.standardizedFileURL.resolvingSymlinksInPath()
    let projectRoot = project.root.standardizedFileURL.resolvingSymlinksInPath()
    guard candidate != projectRoot else {
      return
    }

    let actual = try FileSystem.relativeRegularFiles(under: candidateRoot)
    let expected =
      (project.upstreamFiles
      + project.transformedSources
      + project.adaptedSources.map(\.destination)
      + project.liteSources
      + MaintenanceProject.generatedSourcePaths).sorted()
    try require(
      actual == expected,
      treeDifferenceMessage(
        label: "candidate import tree",
        expected: expected,
        actual: actual
      )
    )
  }

  private static func verifyExactSourceTree(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    let sourceRoot = candidateRoot.appendingPathComponent(
      "Sources/SwiftFormat",
      isDirectory: true
    )
    let actual = try FileSystem.relativeRegularFiles(under: sourceRoot).map {
      "Sources/SwiftFormat/\($0)"
    }
    let expected = expectedSourcePaths(project)
    try require(
      actual == expected,
      treeDifferenceMessage(
        label: "candidate source tree",
        expected: expected,
        actual: actual
      )
    )
  }

  private static func verifyUpstreamOwnedFiles(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    for path in project.upstreamFiles {
      let candidate = relativeURL(path, under: candidateRoot)
      try FileSystem.requireRegularFile(candidate, label: "A-owned file in candidate")

      let expectedBlob: String
      do {
        expectedBlob = try project.upstreamBlob(path: path)
      } catch {
        throw MaintenanceError("missing or renamed upstream file: \(path)")
      }
      let actualBlob = try project.blob(of: candidate)
      try require(
        actualBlob == expectedBlob,
        "A-owned file differs from pinned upstream: \(path)"
      )
    }
  }

  private static func verifyMechanicallyTransformedFiles(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    for path in project.transformedSources {
      let candidate = relativeURL(path, under: candidateRoot)
      try FileSystem.requireRegularFile(
        candidate,
        label: "mechanically transformed source in candidate"
      )
      let expected = try UpstreamImporter.transformedUpstreamData(
        project: project,
        path: path
      )
      let actual = try FileSystem.readData(candidate)
      try require(
        actual == expected,
        "mechanically transformed source differs from generated upstream content: \(path)"
      )
    }
  }

  private static func verifyAdaptedAndLiteFiles(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    try UpstreamImporter.verifyAdaptedSourceBlobs(project)

    for source in project.adaptedSources {
      let destination = relativeURL(source.destination, under: candidateRoot)
      try FileSystem.requireRegularFile(
        destination,
        label: "adapted source snapshot"
      )
    }
    for path in project.liteSources {
      let destination = relativeURL(path, under: candidateRoot)
      try FileSystem.requireRegularFile(destination, label: "Lite-owned source")
    }
  }

  private static func verifyGeneratedFiles(
    candidateRoot: URL,
    generatedFiles: GeneratedRuleFiles
  ) throws {
    for path in MaintenanceProject.generatedSourcePaths {
      guard let expected = generatedFiles.contentsByPath[path] else {
        throw MaintenanceError("missing expected generated contents: \(path)")
      }
      let actual = try FileSystem.readData(relativeURL(path, under: candidateRoot))
      try require(actual == expected, "generated rule file is stale or edited: \(path)")
    }
  }

  private static func verifyRuleSources(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    for rule in project.rules {
      let path = ruleSourcePath(rule)
      let file = relativeURL(path, under: candidateRoot)
      try require(
        FileManager.default.fileExists(atPath: file.path),
        "expected formatter rule source is absent: \(path)"
      )
      let text = try FileSystem.readText(file)
      try require(
        !text.contains("SyntaxLintRule"),
        "lint rule was imported into formatter rule source: \(path)"
      )
    }
  }

  private static func verifyFoundationIsolation(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    let compatibilityImport =
      """
      #if canImport(FoundationEssentials)
      import FoundationEssentials
      #else
      import Foundation
      #endif
      """
    let compatibilitySources: Set<String> = [
      "Sources/SwiftFormat/API/Configuration.swift",
      "Sources/SwiftFormat/API/SwiftFormatError.swift",
      "Sources/SwiftFormat/API/SwiftFormatter.swift",
    ]

    for path in expectedSourcePaths(project) {
      let text = try FileSystem.readText(relativeURL(path, under: candidateRoot))
      let foundationImportCount = text.split(
        separator: "\n",
        omittingEmptySubsequences: false
      ).count { $0 == "import Foundation" }

      if compatibilitySources.contains(path) {
        try require(
          foundationImportCount == 1 && text.contains(compatibilityImport),
          "Foundation compatibility import is missing or malformed: \(path)"
        )
      } else {
        try require(
          foundationImportCount == 0,
          "unconditional Foundation import is not allowed in Lite sources: \(path)"
        )
      }
    }
  }

  private static func verifyExcludedSourceFeatures(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws {
    let hits = try scanTextFiles(
      root: candidateRoot,
      paths: expectedSourcePaths(project),
      patterns: [
        #"format\(contentsOf:"#,
        #"Configuration\(contentsOf:"#,
        #"String\(contentsOf:"#,
        #"Data\(contentsOf:"#,
        #"\bFileManager\b"#,
        #"\bFileHandle\b"#,
        #"\bURL\b"#,
        #"assumingFileURL"#,
        #"url\(forConfigurationFileApplyingTo"#,
        #"@_spi\(ExperimentalLanguageFeatures\)"#,
        #"\bParser\.ExperimentalFeatures\b"#,
        #"\bexperimentalFeatures\b"#,
        #"printTokenStream"#,
        #"printDebugToken"#,
        #"^\s*print\("#,
        #"\bCharacterSet\b"#,
        #"\.trimmingCharacters\("#,
        #"\.rangeOfCharacter\("#,
      ]
    )
    try require(
      hits.isEmpty,
      "library Sources contain excluded file I/O, parser SPI, or console output:\n"
        + formatHits(hits)
    )
  }

  private static func expectedSourcePaths(_ project: MaintenanceProject) -> [String] {
    let aSources = project.upstreamFiles.filter {
      $0.hasPrefix("Sources/SwiftFormat/")
    }
    let transformedSources = project.transformedSources
    let cSources = project.adaptedSources.map(\.destination)
    return
      (aSources + transformedSources + cSources + project.liteSources
      + MaintenanceProject.generatedSourcePaths).sorted()
  }
}

func treeDifferenceMessage(
  label: String,
  expected: [String],
  actual: [String]
) -> String {
  let expectedSet = Set(expected)
  let actualSet = Set(actual)
  let missing = expectedSet.subtracting(actualSet).sorted()
  let unexpected = actualSet.subtracting(expectedSet).sorted()
  var details = ["\(label) differs from its fail-closed manifest"]
  if !missing.isEmpty {
    details.append("missing: \(missing.joined(separator: ", "))")
  }
  if !unexpected.isEmpty {
    details.append("unexpected: \(unexpected.joined(separator: ", "))")
  }
  if missing.isEmpty && unexpected.isEmpty {
    details.append("file ordering differs")
  }
  return details.joined(separator: "\n")
}

func formatHits(_ hits: [TextHit], limit: Int = 20) -> String {
  let visible = hits.prefix(limit).map(\.description)
  var lines = Array(visible)
  if hits.count > limit {
    lines.append("… and \(hits.count - limit) more")
  }
  return lines.joined(separator: "\n")
}
