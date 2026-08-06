import Foundation

struct ProcessOutput {
  let standardOutput: Data
  let standardError: Data

  var outputText: String {
    String(decoding: standardOutput, as: UTF8.self)
  }

  var errorText: String {
    String(decoding: standardError, as: UTF8.self)
  }
}

enum ProcessRunner {
  static func run(
    _ executable: String,
    arguments: [String],
    currentDirectory: URL
  ) throws -> ProcessOutput {
    let captureDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(
        "swift-format-lite-process-\(UUID().uuidString)",
        isDirectory: true
      )
    let outputURL = captureDirectory.appendingPathComponent("stdout")
    let errorURL = captureDirectory.appendingPathComponent("stderr")
    do {
      try FileManager.default.createDirectory(
        at: captureDirectory,
        withIntermediateDirectories: true
      )
      try Data().write(to: outputURL)
      try Data().write(to: errorURL)
    } catch {
      throw MaintenanceError(
        "could not prepare process capture files: \(error.localizedDescription)"
      )
    }
    defer {
      try? FileManager.default.removeItem(at: captureDirectory)
    }

    let process = Process()
    let outputHandle: FileHandle
    let errorHandle: FileHandle
    do {
      outputHandle = try FileHandle(forWritingTo: outputURL)
      errorHandle = try FileHandle(forWritingTo: errorURL)
    } catch {
      throw MaintenanceError(
        "could not open process capture files: \(error.localizedDescription)"
      )
    }

    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory
    process.standardOutput = outputHandle
    process.standardError = errorHandle

    do {
      try process.run()
    } catch {
      try? outputHandle.close()
      try? errorHandle.close()
      throw MaintenanceError("could not run \(executable): \(error.localizedDescription)")
    }

    process.waitUntilExit()
    try outputHandle.close()
    try errorHandle.close()
    let standardOutput = try Data(contentsOf: outputURL)
    let standardError = try Data(contentsOf: errorURL)
    let result = ProcessOutput(
      standardOutput: standardOutput,
      standardError: standardError
    )

    guard process.terminationStatus == 0 else {
      let details = result.errorText.trimmingCharacters(in: .whitespacesAndNewlines)
      let suffix = details.isEmpty ? "" : ": \(details)"
      throw MaintenanceError(
        "\(executable) \(arguments.joined(separator: " ")) failed"
          + " with status \(process.terminationStatus)\(suffix)"
      )
    }

    return result
  }

  static func text(
    _ executable: String,
    arguments: [String],
    currentDirectory: URL
  ) throws -> String {
    try run(
      executable,
      arguments: arguments,
      currentDirectory: currentDirectory
    ).outputText
  }
}
