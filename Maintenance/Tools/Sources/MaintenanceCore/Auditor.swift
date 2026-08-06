import Foundation

struct AuditResult {
  let sourceFileCount: Int
  let ruleCount: Int
  let suiteCount: Int
  let testCount: Int
}

enum Auditor {
  static func run(
    project: MaintenanceProject,
    candidateRoot: URL
  ) throws -> AuditResult {
    try EnvironmentVerifier.verify(project)
    let generatedFiles = try RuleGenerator.makeFiles(project: project)
    let sourceResult = try SourceAuditor.run(
      project: project,
      candidateRoot: candidateRoot,
      generatedFiles: generatedFiles
    )
    let testResult = try TestAuditor.run(project: project)

    return AuditResult(
      sourceFileCount: sourceResult.sourceFileCount,
      ruleCount: project.rules.count,
      suiteCount: testResult.suiteCount,
      testCount: testResult.testCount
    )
  }
}

public enum AuditTool {
  public static func run(projectRoot: URL, candidateRoot: URL?) throws {
    let project = try MaintenanceProject.load(root: projectRoot)
    let auditedRoot = candidateRoot ?? project.root
    let result = try Auditor.run(
      project: project,
      candidateRoot: auditedRoot
    )
    print(
      "audit: verified \(result.sourceFileCount) source files, "
        + "\(result.ruleCount) formatter rules, and \(result.testCount) tests "
        + "in \(result.suiteCount) suites at \(auditedRoot.path)"
    )
  }
}
