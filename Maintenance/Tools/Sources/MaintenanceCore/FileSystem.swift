import Foundation

enum FileSystem {
  static let manager = FileManager.default

  static func readText(_ url: URL) throws -> String {
    do {
      return try String(contentsOf: url, encoding: .utf8)
    } catch {
      throw MaintenanceError(
        "could not read \(url.path): \(error.localizedDescription)"
      )
    }
  }

  static func readData(_ url: URL) throws -> Data {
    do {
      return try Data(contentsOf: url)
    } catch {
      throw MaintenanceError(
        "could not read \(url.path): \(error.localizedDescription)"
      )
    }
  }

  static func write(_ data: Data, to url: URL) throws {
    try createParentDirectory(for: url)
    do {
      try data.write(to: url, options: .atomic)
      try manager.setAttributes(
        [.posixPermissions: NSNumber(value: 0o644)],
        ofItemAtPath: url.path
      )
    } catch {
      throw MaintenanceError(
        "could not write \(url.path): \(error.localizedDescription)"
      )
    }
  }

  static func requireRegularFile(_ url: URL, label: String) throws {
    let values: URLResourceValues
    do {
      values = try url.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
    } catch {
      throw MaintenanceError(
        "could not inspect \(url.path): \(error.localizedDescription)"
      )
    }

    try require(values.isRegularFile == true, "missing \(label): \(url.path)")
    try require(values.isSymbolicLink != true, "\(label) must not be a symlink: \(url.path)")
  }

  static func copyRegularFile(from source: URL, to destination: URL) throws {
    try requireRegularFile(source, label: "local source snapshot")
    try createParentDirectory(for: destination)

    do {
      try manager.copyItem(at: source, to: destination)
    } catch {
      throw MaintenanceError(
        "could not copy \(source.path) to \(destination.path): \(error.localizedDescription)"
      )
    }
  }

  static func prepareEmptyDirectory(_ url: URL, projectRoot: URL) throws {
    let normalized = url.standardizedFileURL
    let protectedRoots = [
      projectRoot.appendingPathComponent("Sources/SwiftFormat").standardizedFileURL,
      projectRoot.appendingPathComponent("Tests/SwiftFormatTests").standardizedFileURL,
    ]
    try require(
      normalized != projectRoot.standardizedFileURL
        && protectedRoots.allSatisfy { !pathsOverlap(normalized, $0) },
      "refusing to use a protected project path as output: \(normalized.path)"
    )

    var isDirectory: ObjCBool = false
    if manager.fileExists(atPath: normalized.path, isDirectory: &isDirectory) {
      try require(isDirectory.boolValue, "output exists and is not a directory: \(normalized.path)")
      let contents = try manager.contentsOfDirectory(atPath: normalized.path)
      try require(contents.isEmpty, "output directory must be empty: \(normalized.path)")
      return
    }

    do {
      try manager.createDirectory(
        at: normalized,
        withIntermediateDirectories: true
      )
    } catch {
      throw MaintenanceError(
        "could not create output directory \(normalized.path): \(error.localizedDescription)"
      )
    }
  }

  static func createParentDirectory(for url: URL) throws {
    let parent = url.deletingLastPathComponent()
    do {
      try manager.createDirectory(
        at: parent,
        withIntermediateDirectories: true
      )
    } catch {
      throw MaintenanceError(
        "could not create directory \(parent.path): \(error.localizedDescription)"
      )
    }
  }

  static func relativeRegularFiles(under root: URL) throws -> [String] {
    guard
      let enumerator = manager.enumerator(
        at: root,
        includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
        options: []
      )
    else {
      throw MaintenanceError("could not enumerate \(root.path)")
    }

    var files: [String] = []
    for case let fileURL as URL in enumerator {
      let values = try fileURL.resourceValues(
        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
      )
      if values.isSymbolicLink == true {
        throw MaintenanceError("symlinks are not allowed in audited trees: \(fileURL.path)")
      }
      guard values.isRegularFile == true else {
        continue
      }

      let rootPath = root.standardizedFileURL.path
      let filePath = fileURL.standardizedFileURL.path
      let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
      try require(filePath.hasPrefix(prefix), "enumerated path escaped its root: \(filePath)")
      files.append(String(filePath.dropFirst(prefix.count)))
    }

    return files.sorted()
  }

  static func removeIfPresent(_ url: URL) throws {
    guard manager.fileExists(atPath: url.path) else {
      return
    }
    do {
      try manager.removeItem(at: url)
    } catch {
      throw MaintenanceError(
        "could not remove \(url.path): \(error.localizedDescription)"
      )
    }
  }
}

private func pathsOverlap(_ first: URL, _ second: URL) -> Bool {
  let firstPath = first.standardizedFileURL.resolvingSymlinksInPath().path
  let secondPath = second.standardizedFileURL.resolvingSymlinksInPath().path
  if firstPath == secondPath {
    return true
  }
  return firstPath.hasPrefix(secondPath + "/")
    || secondPath.hasPrefix(firstPath + "/")
}

func relativeURL(_ path: String, under root: URL) -> URL {
  path.split(separator: "/").reduce(root) { result, component in
    result.appendingPathComponent(String(component))
  }
}

func nonCommentLines(in text: String) -> [String] {
  text.split(whereSeparator: \.isNewline).compactMap { rawLine in
    let line = rawLine.trimmingCharacters(in: .whitespaces)
    if line.isEmpty || line.hasPrefix("#") {
      return nil
    }
    return line
  }
}
