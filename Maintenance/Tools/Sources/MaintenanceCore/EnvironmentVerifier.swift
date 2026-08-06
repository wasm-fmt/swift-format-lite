import Foundation

enum EnvironmentVerifier {
  static func verify(_ project: MaintenanceProject) throws {
    try verifySwiftVersion(project)
    try verifySwiftFormatTag(project)
    try verifyPackagePins(project)
    try verifySwiftSyntaxTag(project)
  }

  private static func verifySwiftVersion(_ project: MaintenanceProject) throws {
    let versionOutput = try ProcessRunner.text(
      "swift",
      arguments: ["--version"],
      currentDirectory: project.root
    )
    guard
      let actualVersion = try firstRegexCapture(
        pattern: #"Swift version ([0-9]+(?:\.[0-9]+)+)"#,
        in: versionOutput
      )
    else {
      throw MaintenanceError("could not determine the active Swift version")
    }
    try require(
      actualVersion == project.lock.swiftVersion,
      "active Swift \(actualVersion) does not match locked Swift \(project.lock.swiftVersion)"
    )
  }

  private static func verifySwiftFormatTag(_ project: MaintenanceProject) throws {
    let actualSHA = try ProcessRunner.text(
      "git",
      arguments: [
        "rev-parse",
        "--verify",
        "refs/tags/\(project.lock.swiftFormatTag)^{commit}",
      ],
      currentDirectory: project.root
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      actualSHA == project.lock.swiftFormatSHA,
      "local tag \(project.lock.swiftFormatTag) does not resolve to the locked swift-format SHA"
    )
  }

  private static func verifyPackagePins(_ project: MaintenanceProject) throws {
    let packageText = try FileSystem.readText(
      project.root.appendingPathComponent("Package.swift")
    )
    let exactVersion = #"exact: "\#(project.lock.swiftSyntaxTag)""#
    try require(
      packageText.contains(exactVersion),
      "Package.swift does not use the locked stable swift-syntax version"
    )
    try require(
      !packageText.contains("revision:") && !packageText.contains("branch:"),
      "Package.swift must not use unstable branch or revision dependencies"
    )

    let firstLine = packageText.split(
      separator: "\n",
      maxSplits: 1,
      omittingEmptySubsequences: false
    ).first.map(String.init)
    try require(
      firstLine == "// swift-tools-version: \(project.lock.swiftToolsVersion)",
      "Package.swift does not use the locked Swift tools version"
    )
  }

  private static func verifySwiftSyntaxTag(_ project: MaintenanceProject) throws {
    let environmentPath = ProcessInfo.processInfo.environment["SWIFTSYNTAX_CHECKOUT"]
    let checkout: URL
    if let environmentPath {
      checkout =
        URL(
          fileURLWithPath: environmentPath,
          relativeTo: project.root
        ).standardizedFileURL
    } else {
      checkout = project.root.appendingPathComponent(
        ".build/checkouts/swift-syntax",
        isDirectory: true
      )
    }

    let gitMetadata = checkout.appendingPathComponent(".git")
    try require(
      FileManager.default.fileExists(atPath: gitMetadata.path),
      "swift-syntax checkout is required locally; set SWIFTSYNTAX_CHECKOUT"
    )

    let actualSHA = try ProcessRunner.text(
      "git",
      arguments: [
        "-C",
        checkout.path,
        "rev-parse",
        "--verify",
        "refs/tags/\(project.lock.swiftSyntaxTag)^{commit}",
      ],
      currentDirectory: project.root
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      actualSHA == project.lock.swiftSyntaxSHA,
      "local swift-syntax tag \(project.lock.swiftSyntaxTag) does not resolve to the locked revision"
    )
  }
}
