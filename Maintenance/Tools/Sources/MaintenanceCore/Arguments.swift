import Foundation

public struct ToolArguments {
  public let projectRoot: URL
  public let value: URL?

  public static func parse(
    command: String,
    valueOption: String? = nil,
    valueRequired: Bool = false
  ) throws -> ToolArguments {
    var projectRoot: URL?
    var value: URL?
    var index = 1
    let arguments = CommandLine.arguments

    while index < arguments.count {
      let argument = arguments[index]
      switch argument {
      case "--project-root":
        projectRoot = try parseURLValue(
          arguments: arguments,
          index: &index,
          option: argument
        )

      case "--help", "-h":
        throw MaintenanceError(usage(command: command, valueOption: valueOption))

      default:
        if let valueOption, argument == valueOption {
          value = try parseURLValue(
            arguments: arguments,
            index: &index,
            option: argument
          )
        } else {
          throw MaintenanceError(
            "unexpected argument '\(argument)'\n"
              + usage(command: command, valueOption: valueOption)
          )
        }
      }

      index += 1
    }

    guard let projectRoot else {
      throw MaintenanceError(
        "missing --project-root\n\(usage(command: command, valueOption: valueOption))"
      )
    }
    if valueRequired && value == nil {
      throw MaintenanceError(
        "missing \(valueOption ?? "required path option")\n"
          + usage(command: command, valueOption: valueOption)
      )
    }

    return ToolArguments(projectRoot: projectRoot, value: value)
  }

  private static func parseURLValue(
    arguments: [String],
    index: inout Int,
    option: String
  ) throws -> URL {
    let valueIndex = index + 1
    guard valueIndex < arguments.count else {
      throw MaintenanceError("\(option) requires a path")
    }

    let value = arguments[valueIndex]
    guard !value.hasPrefix("--") else {
      throw MaintenanceError("\(option) requires a path")
    }

    index = valueIndex
    let currentDirectory = URL(
      fileURLWithPath: FileManager.default.currentDirectoryPath,
      isDirectory: true
    )
    return URL(fileURLWithPath: value, relativeTo: currentDirectory).standardizedFileURL
  }

  private static func usage(command: String, valueOption: String?) -> String {
    var result = "usage: \(command) --project-root <path>"
    if let valueOption {
      result += " \(valueOption) <path>"
    }
    return result
  }
}
