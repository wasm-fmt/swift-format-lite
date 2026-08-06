//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License 2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormat

extension Configuration {
  /// The default configuration to be used during unit tests.
  ///
  /// This is kept separate from `Configuration.init()` so that tests do not implicitly depend on
  /// changes to the production defaults.
  static var forTesting: Configuration {
    var config = Configuration()
    config.rules = Configuration.defaultRuleEnablements
    config.maximumBlankLines = 1
    config.lineLength = 100
    config.tabWidth = 8
    config.indentation = .spaces(2)
    config.respectsExistingLineBreaks = true
    config.lineBreakBeforeControlFlowKeywords = false
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = false
    config.prioritizeKeepingFunctionOutputTogether = false
    config.indentConditionalCompilationBlocks = true
    config.lineBreakAroundMultilineExpressionChainComponents = false
    config.fileScopedDeclarationPrivacy = FileScopedDeclarationPrivacyConfiguration()
    config.indentSwitchCaseLabels = false
    config.spacesAroundRangeFormationOperators = false
    config.noAssignmentInExpressions = NoAssignmentInExpressionsConfiguration()
    config.multiElementCollectionTrailingCommas = true
    config.indentBlankLines = false
    return config
  }

  /// Returns a test configuration with only the named rule enabled.
  static func forTesting(enabledRule: String) -> Configuration {
    var config = forTesting
    config.rules = config.rules.mapValues { _ in false }
    config.rules[enabledRule] = true
    return config
  }
}
