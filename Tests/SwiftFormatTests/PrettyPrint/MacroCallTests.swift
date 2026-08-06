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

import SwiftFormat

@Suite
final class MacroCallTests: PrettyPrintTestCase {
  @Test
  func testNoWhiteSpaceAfterMacroWithoutTrailingClosure() {
    let input =
      """
      func myFunction() {
        print("Currently running \\(#function)")
      }

      """

    let expected =
      """
      func myFunction() {
        print("Currently running \\(#function)")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test
  func testKeepWhiteSpaceBeforeTrailingClosure() {
    let input =
      """
      #Preview {}
      #Preview("MyPreview") {
        MyView()
      }
      let p = #Predicate<Int> { $0 == 0 }
      """

    let expected =
      """
      #Preview {}
      #Preview("MyPreview") {
        MyView()
      }
      let p = #Predicate<Int> { $0 == 0 }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  @Test
  func testInsertWhiteSpaceBeforeTrailingClosure() {
    let input =
      """
      #Preview{}
      #Preview("MyPreview"){
        MyView()
      }
      let p = #Predicate<Int>{ $0 == 0 }
      """

    let expected =
      """
      #Preview {}
      #Preview("MyPreview") {
        MyView()
      }
      let p = #Predicate<Int> { $0 == 0 }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  @Test
  func testDiscretionaryLineBreakBeforeTrailingClosure() {
    let input =
      """
      #Preview("MyPreview")
      {
        MyView()
      }
      #Preview(
        "MyPreview", traits: .landscapeLeft
      )
      {
        MyView()
      }
      #Preview("MyPreview", traits: .landscapeLeft, .sizeThatFitsLayout)
      {
        MyView()
      }
      #Preview("MyPreview", traits: .landscapeLeft) {
        MyView()
      }
      """

    let expected =
      """
      #Preview("MyPreview") {
        MyView()
      }
      #Preview(
        "MyPreview", traits: .landscapeLeft
      ) {
        MyView()
      }
      #Preview(
        "MyPreview", traits: .landscapeLeft,
        .sizeThatFitsLayout
      ) {
        MyView()
      }
      #Preview("MyPreview", traits: .landscapeLeft)
      {
        MyView()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  @Test
  func testMacroDeclWithAttributesAndArguments() {
    let input = """
      @nonsenseAttribute
      @available(iOS 17.0, *)
      #Preview("Name") {
        EmptyView()
      }

      """
    assertPrettyPrintEqual(input: input, expected: input, linelength: 45)
  }
}
