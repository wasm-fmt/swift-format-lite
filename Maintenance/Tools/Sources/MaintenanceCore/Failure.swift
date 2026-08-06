import Foundation

#if canImport(Darwin)
  import Darwin
#else
  import Glibc
#endif

public struct MaintenanceError: Error, CustomStringConvertible, LocalizedError {
  public let description: String

  public init(_ description: String) {
    self.description = description
  }

  public var errorDescription: String? {
    description
  }
}

@inline(__always)
func require(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String)
  throws
{
  guard condition() else {
    throw MaintenanceError(message())
  }
}

public func runMaintenanceMain(
  command: String,
  _ operation: () throws -> Void
) {
  do {
    try operation()
  } catch {
    let message: String
    if let maintenanceError = error as? MaintenanceError {
      message = maintenanceError.description
    } else {
      message = error.localizedDescription
    }

    let output = "\(command): \(message)\n"
    FileHandle.standardError.write(Data(output.utf8))
    exit(EXIT_FAILURE)
  }
}
