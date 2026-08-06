//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Errors that can be thrown by the `SwiftFormatter` API.
public enum SwiftFormatError: LocalizedError {

  /// The file contains invalid or unrecognized Swift syntax and cannot be handled safely.
  case fileContainsInvalidSyntax

  /// The provided configuration version is not supported by this version of the formatter.
  case unsupportedConfigurationVersion(Int, highestSupported: Int)

  public var errorDescription: String? {
    switch self {
    case .fileContainsInvalidSyntax:
      return "file contains invalid Swift syntax"
    case .unsupportedConfigurationVersion(let version, let highestSupported):
      return
        "This version of the formatter does not support configuration version \(version). The highest supported version is \(highestSupported)."
    }
  }
}

extension SwiftFormatError: Equatable {}
extension SwiftFormatError: Hashable {}
