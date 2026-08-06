//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Testing

@_spi(Rules) import SwiftFormat

@Suite
final class NoAssignmentInExpressionsTests: LintOrFormatRuleTestCase {
  @Test
  func testAssignmentInExpressionContextIsDiagnosed() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        foo(bar, 1️⃣baz = quux, a + b)
        """,
      expected: """
        foo(bar, baz = quux, a + b)
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }

  @Test
  func testReturnStatementWithoutExpressionIsUnchanged() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return
        }
        """,
      expected: """
        func foo() {
          return
        }
        """,
      findings: []
    )
  }

  @Test
  func testReturnStatementWithNonAssignmentExpressionIsUnchanged() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return a + b
        }
        """,
      expected: """
        func foo() {
          return a + b
        }
        """,
      findings: []
    )
  }

  @Test
  func testReturnStatementWithSimpleAssignmentExpressionIsExpanded() throws {
    // For this and similar tests below, we don't try to match the leading indentation in the new
    // `return` statement; the pretty-printer will fix it up.
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return 1️⃣a = b
        }
        """,
      expected: """
        func foo() {
          a = b
        return
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }

  @Test
  func testReturnStatementWithCompoundAssignmentExpressionIsExpanded() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return 1️⃣a += b
        }
        """,
      expected: """
        func foo() {
          a += b
        return
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }

  @Test
  func testReturnStatementWithAssignmentDealsWithLeadingLineCommentSensibly() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          // some comment
          return 1️⃣a = b
        }
        """,
      expected: """
        func foo() {
          // some comment
          a = b
        return
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }

  @Test
  func testReturnStatementWithAssignmentDealsWithTrailingLineCommentSensibly() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return 1️⃣a = b  // some comment
        }
        """,
      expected: """
        func foo() {
          a = b
        return  // some comment
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }

  @Test
  func testReturnStatementWithAssignmentDealsWithTrailingBlockCommentSensibly() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return 1️⃣a = b  /* some comment */
        }
        """,
      expected: """
        func foo() {
          a = b
        return  /* some comment */
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }

  @Test
  func testReturnStatementWithAssignmentDealsWithNestedBlockCommentSensibly() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return /* some comment */ 1️⃣a = b
        }
        """,
      expected: """
        func foo() {
          /* some comment */ a = b
        return
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }

  @Test
  func testTryAndAwaitAndUnsafeAssignmentExpressionsAreUnchanged() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          try a.b = c
          await a.b = c
          unsafe a.b = c
        }
        """,
      expected: """
        func foo() {
          try a.b = c
          await a.b = c
          unsafe a.b = c
        }
        """,
      findings: []
    )
  }

  @Test
  func testAssignmentExpressionsInAllowedFunctions() throws {
    try assertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        // These should not diagnose.
        XCTAssertNoThrow(a = try b())
        XCTAssertNoThrow { a = try b() }
        XCTAssertNoThrow({ a = try b() })
        someRegularFunction({ a = b })
        someRegularFunction { a = b }

        // This should be diagnosed.
        someRegularFunction(1️⃣a = b)
        """,
      expected: """
        // These should not diagnose.
        XCTAssertNoThrow(a = try b())
        XCTAssertNoThrow { a = try b() }
        XCTAssertNoThrow({ a = try b() })
        someRegularFunction({ a = b })
        someRegularFunction { a = b }

        // This should be diagnosed.
        someRegularFunction(a = b)
        """,
      findings: [
        FindingSpec("1️⃣", message: "move this assignment expression into its own statement")
      ]
    )
  }
}
