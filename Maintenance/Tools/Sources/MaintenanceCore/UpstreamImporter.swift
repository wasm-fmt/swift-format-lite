import Foundation

struct ImportResult {
  let upstreamFileCount: Int
  let transformedSourceCount: Int
  let adaptedSourceCount: Int
  let liteSourceCount: Int
}

enum UpstreamImporter {
  static func run(
    project: MaintenanceProject,
    outputRoot: URL
  ) throws -> ImportResult {
    try verifyAdaptedSourceBlobs(project)

    var upstreamContents: [String: Data] = [:]
    for path in project.upstreamFiles {
      let data: Data
      do {
        data = try project.upstreamData(path: path)
      } catch {
        throw MaintenanceError("missing or renamed upstream file: \(path)")
      }
      upstreamContents[path] = data
    }
    var transformedContents: [String: Data] = [:]
    for path in project.transformedSources {
      transformedContents[path] = try transformedUpstreamData(
        project: project,
        path: path
      )
    }
    for source in project.adaptedSources {
      try FileSystem.requireRegularFile(
        relativeURL(source.destination, under: project.root),
        label: "adapted source snapshot"
      )
    }
    for path in project.liteSources {
      try FileSystem.requireRegularFile(
        relativeURL(path, under: project.root),
        label: "Lite-owned source"
      )
    }

    try FileSystem.prepareEmptyDirectory(outputRoot, projectRoot: project.root)
    for path in project.upstreamFiles {
      guard let data = upstreamContents[path] else {
        throw MaintenanceError("preflight omitted upstream file: \(path)")
      }
      try FileSystem.write(data, to: relativeURL(path, under: outputRoot))
    }

    for path in project.transformedSources {
      guard let data = transformedContents[path] else {
        throw MaintenanceError("preflight omitted mechanically transformed source: \(path)")
      }
      try FileSystem.write(data, to: relativeURL(path, under: outputRoot))
    }

    for source in project.adaptedSources {
      try FileSystem.copyRegularFile(
        from: relativeURL(source.destination, under: project.root),
        to: relativeURL(source.destination, under: outputRoot)
      )
    }

    for path in project.liteSources {
      try FileSystem.copyRegularFile(
        from: relativeURL(path, under: project.root),
        to: relativeURL(path, under: outputRoot)
      )
    }

    return ImportResult(
      upstreamFileCount: project.upstreamFiles.count,
      transformedSourceCount: project.transformedSources.count,
      adaptedSourceCount: project.adaptedSources.count,
      liteSourceCount: project.liteSources.count
    )
  }

  static func transformedUpstreamData(
    project: MaintenanceProject,
    path: String
  ) throws -> Data {
    let upstreamData: Data
    do {
      upstreamData = try project.upstreamData(path: path)
    } catch {
      throw MaintenanceError("missing or renamed transformed upstream source: \(path)")
    }

    guard let upstreamText = String(data: upstreamData, encoding: .utf8) else {
      throw MaintenanceError("transformed upstream source is not UTF-8: \(path)")
    }

    var lines = upstreamText.split(
      separator: "\n",
      omittingEmptySubsequences: false
    ).map(String.init)
    let importLines = lines.indices.filter { lines[$0] == "import Foundation" }
    try require(
      importLines.count == 1,
      "mechanical Foundation import transform expected exactly one matching line: \(path)"
    )
    lines.remove(at: importLines[0])
    return Data(lines.joined(separator: "\n").utf8)
  }

  static func verifyAdaptedSourceBlobs(_ project: MaintenanceProject) throws {
    for source in project.adaptedSources {
      let actualBlob: String
      do {
        actualBlob = try project.upstreamBlob(path: source.upstreamSource)
      } catch {
        throw MaintenanceError(
          "upstream adapted source changed, deleted, or renamed: "
            + "\(source.upstreamSource) (destination \(source.destination))"
        )
      }
      try require(
        actualBlob == source.upstreamBlob,
        "upstream adapted source changed, deleted, or renamed: "
          + "\(source.upstreamSource) (destination \(source.destination))"
      )
    }
  }
}

public enum ImportUpstreamTool {
  public static func run(projectRoot: URL, outputRoot: URL) throws {
    let project = try MaintenanceProject.load(root: projectRoot)
    try EnvironmentVerifier.verify(project)
    let result = try UpstreamImporter.run(
      project: project,
      outputRoot: outputRoot
    )
    let liteNoun = result.liteSourceCount == 1 ? "source" : "sources"
    print(
      "import-upstream: staged \(result.upstreamFileCount) exact upstream files, "
        + "\(result.transformedSourceCount) mechanically transformed sources, "
        + "\(result.adaptedSourceCount) adapted snapshots, and "
        + "\(result.liteSourceCount) Lite-owned \(liteNoun) at \(outputRoot.path)"
    )
  }
}
