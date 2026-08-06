import Foundation

struct TestAuditResult {
  let suiteCount: Int
  let testCount: Int
}

enum TestAuditor {
  private static let configurationMethods = [
    "testDefaultConfigurationIsSameAsEmptyDecode",
    "testDecodingReflowMultilineStringLiteralsAsString",
    "testDecodingReflowMultilineStringLiteralsAsObject",
    "testConfigurationWithComments",
  ]

  private static let categoryExpectations: [String: (suites: Int, tests: Int)] = [
    "API": (1, 4),
    "Core": (2, 24),
    "PrettyPrint": (68, 559),
    "Rules": (25, 172),
  ]

  static func run(project: MaintenanceProject) throws -> TestAuditResult {
    try verifyExactTestTree(project)
    let texts = try verifySnapshotsAndMethods(project)
    let counts = try verifyCounts(project: project, texts: texts)
    try verifyExcludedTestFeatures(project)
    return counts
  }

  private static func verifyExactTestTree(_ project: MaintenanceProject) throws {
    let testRoot = project.root.appendingPathComponent(
      "Tests/SwiftFormatTests",
      isDirectory: true
    )
    let actual = try FileSystem.relativeRegularFiles(under: testRoot).map {
      "Tests/SwiftFormatTests/\($0)"
    }
    let expected = project.testSources.map(\.destination).sorted()
    try require(
      actual == expected,
      treeDifferenceMessage(
        label: "local test tree",
        expected: expected,
        actual: actual
      )
    )
  }

  private static func verifySnapshotsAndMethods(
    _ project: MaintenanceProject
  ) throws -> [String: String] {
    var texts: [String: String] = [:]

    for source in project.testSources {
      let actualBlob: String
      do {
        actualBlob = try project.upstreamBlob(path: source.upstreamSource)
      } catch {
        throw changedSourceError(source)
      }
      try require(actualBlob == source.upstreamBlob, changedSourceError(source).description)

      let destination = relativeURL(source.destination, under: project.root)
      let text = try FileSystem.readText(destination)
      texts[source.destination] = text

      switch source.kind {
      case .suite:
        try require(
          exactLineCount("@Suite", in: text) == 1,
          "local test snapshot is not exactly one Swift Testing suite: \(source.destination)"
        )
        let actualMethods = try testMethodNames(in: text)
        let expectedMethods: [String]
        if source.destination == "Tests/SwiftFormatTests/API/ConfigurationTests.swift" {
          expectedMethods = configurationMethods
        } else {
          expectedMethods = try testMethodNames(
            in: project.upstreamText(path: source.upstreamSource)
          )
        }
        try require(
          actualMethods == expectedMethods,
          "local test methods differ from the reviewed upstream subset: \(source.destination)"
        )

      case .support:
        try require(
          exactLineCount("@Suite", in: text) == 0,
          "test support unexpectedly declares a suite: \(source.destination)"
        )
      }
    }

    return texts
  }

  private static func verifyCounts(
    project: MaintenanceProject,
    texts: [String: String]
  ) throws -> TestAuditResult {
    let suiteCount = texts.values.reduce(0) {
      $0 + exactLineCount("@Suite", in: $1)
    }
    let testCount = texts.values.reduce(0) {
      $0 + exactLineCount("  @Test", in: $1)
    }
    try require(suiteCount == 96, "expected 96 Swift Testing suites, found \(suiteCount)")
    try require(testCount == 759, "expected 759 tests, found \(testCount)")

    for category in categoryExpectations.keys.sorted() {
      guard let expectation = categoryExpectations[category] else {
        continue
      }
      let prefix = "Tests/SwiftFormatTests/\(category)/"
      let categoryTexts = texts.filter { $0.key.hasPrefix(prefix) }.map(\.value)
      let actualSuites = categoryTexts.reduce(0) {
        $0 + exactLineCount("@Suite", in: $1)
      }
      let actualTests = categoryTexts.reduce(0) {
        $0 + exactLineCount("  @Test", in: $1)
      }
      try require(
        actualSuites == expectation.suites,
        "\(category) suite count changed: expected \(expectation.suites), found \(actualSuites)"
      )
      try require(
        actualTests == expectation.tests,
        "\(category) test count changed: expected \(expectation.tests), found \(actualTests)"
      )
    }

    return TestAuditResult(suiteCount: suiteCount, testCount: testCount)
  }

  private static func verifyExcludedTestFeatures(_ project: MaintenanceProject) throws {
    let hits = try scanTextFiles(
      root: project.root,
      paths: project.testSources.map(\.destination),
      patterns: [
        #"^import XCTest$"#,
        #": XCTestCase"#,
        #"^import _SwiftFormatTestSupport$"#,
        #"^import Markdown$"#,
        #"\bSyntaxLintRule\b"#,
        #"\bSwiftLinter\b"#,
        #"\bLintPipeline\b"#,
        #"\bWhitespaceLinter\b"#,
        #"\bWhitespaceTestCase\b"#,
        #"\bSwiftFormatWasm\b"#,
        #"\bSwiftFormatWASM\b"#,
        #"Data\(contentsOf:"#,
        #"String\(contentsOf:"#,
        #"URL\(fileURLWithPath:"#,
        #"\bFileManager\b"#,
        #"\bFileHandle\b"#,
        #"url\(forConfigurationFileApplyingTo"#,
      ]
    )
    try require(
      hits.isEmpty,
      "local tests contain excluded dependencies, features, or file I/O:\n"
        + formatHits(hits)
    )
  }

  private static func changedSourceError(_ source: TestSource) -> MaintenanceError {
    MaintenanceError(
      "upstream test source changed, deleted, or renamed: "
        + "\(source.upstreamSource) (destination \(source.destination))"
    )
  }
}
