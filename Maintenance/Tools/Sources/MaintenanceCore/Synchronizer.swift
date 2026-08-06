import Foundation

enum TransactionalInstaller {
  static func install(
    project: MaintenanceProject,
    candidateRoot: URL,
    transactionRoot: URL,
    validate: () throws -> Void
  ) throws {
    let topLevelFiles = project.upstreamFiles.filter {
      !$0.hasPrefix("Sources/SwiftFormat/")
    }
    let targets = topLevelFiles + ["Sources/SwiftFormat"]
    let backupRoot = transactionRoot.appendingPathComponent(
      "backup",
      isDirectory: true
    )
    var backedUp: [String] = []
    var installed: [String] = []

    do {
      for path in targets {
        let destination = relativeURL(path, under: project.root)
        guard FileManager.default.fileExists(atPath: destination.path) else {
          continue
        }

        let backup = relativeURL(path, under: backupRoot)
        try FileSystem.createParentDirectory(for: backup)
        try FileManager.default.moveItem(at: destination, to: backup)
        backedUp.append(path)
      }

      for path in targets {
        let candidate = relativeURL(path, under: candidateRoot)
        try require(
          FileManager.default.fileExists(atPath: candidate.path),
          "candidate is missing install target: \(path)"
        )
        let destination = relativeURL(path, under: project.root)
        try FileSystem.createParentDirectory(for: destination)
        try FileManager.default.moveItem(at: candidate, to: destination)
        installed.append(path)
      }

      try validate()
    } catch {
      do {
        try rollback(
          project: project,
          backupRoot: backupRoot,
          backedUp: backedUp,
          installed: installed
        )
      } catch let rollbackError {
        throw MaintenanceError(
          "synchronization failed: \(describe(error)); "
            + "rollback also failed: \(describe(rollbackError))"
        )
      }
      throw error
    }
  }

  private static func rollback(
    project: MaintenanceProject,
    backupRoot: URL,
    backedUp: [String],
    installed: [String]
  ) throws {
    for path in installed.reversed() {
      try FileSystem.removeIfPresent(relativeURL(path, under: project.root))
    }
    for path in backedUp.reversed() {
      let backup = relativeURL(path, under: backupRoot)
      let destination = relativeURL(path, under: project.root)
      try FileSystem.createParentDirectory(for: destination)
      try FileManager.default.moveItem(at: backup, to: destination)
    }
  }

  private static func describe(_ error: Error) -> String {
    if let maintenanceError = error as? MaintenanceError {
      return maintenanceError.description
    }
    return error.localizedDescription
  }
}

public enum SyncUpstreamTool {
  public static func run(projectRoot: URL) throws {
    let project = try MaintenanceProject.load(root: projectRoot)
    try EnvironmentVerifier.verify(project)

    let transactionRoot = project.root
      .appendingPathComponent(".build", isDirectory: true)
      .appendingPathComponent(
        "swift-format-lite-sync-\(UUID().uuidString)",
        isDirectory: true
      )
    let candidateRoot = transactionRoot.appendingPathComponent(
      "candidate",
      isDirectory: true
    )

    try FileManager.default.createDirectory(
      at: transactionRoot,
      withIntermediateDirectories: true
    )
    var installationStarted = false
    var installationCompleted = false
    defer {
      if !installationStarted || installationCompleted {
        try? FileSystem.removeIfPresent(transactionRoot)
      }
    }

    let imported = try UpstreamImporter.run(
      project: project,
      outputRoot: candidateRoot
    )
    let generated = try RuleGenerator.run(
      project: project,
      outputRoot: candidateRoot
    )
    let candidateAudit = try Auditor.run(
      project: project,
      candidateRoot: candidateRoot
    )

    var installedAudit: AuditResult?
    installationStarted = true
    do {
      try TransactionalInstaller.install(
        project: project,
        candidateRoot: candidateRoot,
        transactionRoot: transactionRoot
      ) {
        let result = try Auditor.run(
          project: project,
          candidateRoot: project.root
        )
        try require(
          result.sourceFileCount == candidateAudit.sourceFileCount
            && result.ruleCount == candidateAudit.ruleCount
            && result.suiteCount == candidateAudit.suiteCount
            && result.testCount == candidateAudit.testCount,
          "installed audit summary differs from candidate audit"
        )
        installedAudit = result
      }
    } catch {
      throw MaintenanceError(
        "\(describe(error))\ntransaction preserved at \(transactionRoot.path)"
      )
    }

    guard let installedAudit else {
      throw MaintenanceError(
        "installed source tree was not audited\n"
          + "transaction preserved at \(transactionRoot.path)"
      )
    }
    installationCompleted = true
    let liteNoun = imported.liteSourceCount == 1 ? "source" : "sources"

    print(
      "sync-upstream: installed \(installedAudit.sourceFileCount) source files "
        + "from \(imported.upstreamFileCount) exact upstream files, "
        + "\(imported.adaptedSourceCount) adapted snapshots, "
        + "\(imported.liteSourceCount) Lite-owned \(liteNoun), and "
        + "\(generated.count) generated files; "
        + "audited \(installedAudit.testCount) tests in "
        + "\(installedAudit.suiteCount) suites, and retained "
        + "\(installedAudit.ruleCount) formatter rules from "
        + project.lock.swiftFormatSHA
    )
  }

  private static func describe(_ error: Error) -> String {
    if let maintenanceError = error as? MaintenanceError {
      return maintenanceError.description
    }
    return error.localizedDescription
  }
}
