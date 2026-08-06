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
final class CommaTests: PrettyPrintTestCase {
  @Test
  func testArrayCommasAbsentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testArrayCommasAbsentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testArrayCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testArrayCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2,
        3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,
        3
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testArraySingleLineCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [1, 2, 3,]

      """

    // no effect expected
    let expected =
      """
      let MyCollection = [1, 2, 3]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testArraySingleLineCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [1, 2, 3,]

      """

    // no effect expected
    let expected =
      """
      let MyCollection = [1, 2, 3]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testArrayWithCommentCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2,  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testArrayWithCommentCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        2  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testArrayWithTernaryOperatorAndCommentCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        1,
        true ? 1 : 2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        true ? 1 : 2,  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testArrayWithTernaryOperatorAndCommentCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        1,
        true ? 1 : 2 // some comment
      ]

      """

    let expected =
      """
      let MyCollection = [
        1,
        true ? 1 : 2  // some comment
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testDictionaryCommasAbsentEnabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testDictionaryCommasAbsentDisabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testDictionaryCommasPresentEnabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testDictionaryCommasPresentDisabled() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testDictionarySingleLineCommasPresentDisabled() {
    let input =
      """
      let MyCollection = ["a": 1, "b": 2, "c": 3,]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1, "b": 2, "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testDictionarySingleLineCommasPresentEnabled() {
    let input =
      """
      let MyCollection = ["a": 1, "b": 2, "c": 3,]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1, "b": 2, "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInGenericParameterList() {
    let input =
      """
      struct S<
        T1,
        T2,
        T3
      > {}

      struct S<
        T1,
        T2,
        T3: Foo
      > {}

      """

    let expected =
      """
      struct S<
        T1,
        T2,
        T3,
      > {}

      struct S<
        T1,
        T2,
        T3: Foo,
      > {}

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInTuple() {
    let input =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05
      )

      let (
        velocityX,
        velocityY,
        velocityZ
      ) = velocity

      """

    let expected =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05,
      )

      let (
        velocityX,
        velocityY,
        velocityZ,
      ) = velocity

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInFunction() {
    let input =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...
      ) {}

      foo(
        input1: 1,
        input2: 1
      )
      """

    let expected =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...,
      ) {}

      foo(
        input1: 1,
        input2: 1,
      )

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInInitializer() {
    let input =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0
        ) {}
      }

      """

    let expected =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0,
        ) {}
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInEnumeration() {
    let input =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int
        )
      }

      """

    let expected =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0,
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int,
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInAttribute() {
    let input =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3"
      )
      struct S {}

      """

    let expected =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3",
      )
      struct S {}

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInMacro() {
    let input =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3"
        )
      }

      """

    let expected =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3",
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInKeyPath() {
    let input =
      #"""
      let value = m[
        x,
        y
      ]

      let keyPath = \Foo.bar[
        x,
        y
      ]

      f(\.[
        x,
        y
      ])

      """#

    let expected =
      #"""
      let value = m[
        x,
        y,
      ]

      let keyPath =
        \Foo.bar[
          x,
          y,
        ]

      f(
        \.[
          x,
          y,
        ])

      """#

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysTrailingCommasInClosureCapture() {
    let input =
      """
      { 
        [
          capturedValue1,
          capturedValue2
        ] in
      }

      { 
        [
          capturedValue1,
          capturedValue2 = foo 
        ] in
      }

      """

    let expected =
      """
      {
        [
          capturedValue1,
          capturedValue2,
        ] in
      }

      {
        [
          capturedValue1,
          capturedValue2 = foo,
        ] in
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInGenericParameterList() {
    let input =
      """
      struct S<
        T1,
        T2,
        T3,
      > {}

      struct S<
        T1,
        T2,
        T3: Foo,
      > {}

      """

    let expected =
      """
      struct S<
        T1,
        T2,
        T3
      > {}

      struct S<
        T1,
        T2,
        T3: Foo
      > {}

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInTuple() {
    let input =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05,
      )

      let (
        velocityX,
        velocityY,
        velocityZ,
      ) = velocity

      """

    let expected =
      """
      let velocity = (
        1.66007664274403694e-03,
        7.69901118419740425e-03,
        6.90460016972063023e-05
      )

      let (
        velocityX,
        velocityY,
        velocityZ
      ) = velocity

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInFunction() {
    let input =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int,
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...,
      ) {}

      foo(
        input1: 1,
        input2: 1,
      )
      """

    let expected =
      """
      func foo(
        input1: Int = 0,
        input2: Int = 0
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int
      ) {}

      func foo(
        input1: Int = 0,
        input2: Int...
      ) {}

      foo(
        input1: 1,
        input2: 1
      )

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInInitializer() {
    let input =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0,
        ) {}
      }

      """

    let expected =
      """
      struct S {
        init(
          input1: Int = 0,
          input2: Int = 0
        ) {}
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInEnumeration() {
    let input =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0,
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int,
        )
      }

      """

    let expected =
      """
      enum E {
        case foo(
          input1: Int = 0,
          input2: Int = 0
        )
      }

      enum E {
        case foo(
          input1: Int = 0,
          input2: Int
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInAttribute() {
    let input =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3",
      )
      struct S {}

      """

    let expected =
      """
      @Foo(
        "input 1",
        "input 2",
        "input 3"
      )
      struct S {}

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInMacro() {
    let input =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3",
        )
      }

      """

    let expected =
      """
      struct S {
        #foo(
          "input 1",
          "input 2",
          "input 3"
        )
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInKeyPath() {
    let input =
      #"""
      let value = m[
        x,
        y,
      ]

      let keyPath = \Foo.bar[
        x,
        y,
      ]

      f(\.[
        x,
        y,
      ])

      """#

    let expected =
      #"""
      let value = m[
        x,
        y
      ]

      let keyPath =
        \Foo.bar[
          x,
          y
        ]

      f(
        \.[
          x,
          y
        ])

      """#

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInClosureCapture() {
    let input =
      """
      { 
        [
          capturedValue1,
          capturedValue2,
        ] in
      }

      { 
        [
          capturedValue1,
          capturedValue2 = foo,
        ] in
      }

      """

    let expected =
      """
      {
        [
          capturedValue1,
          capturedValue2
        ] in
      }

      {
        [
          capturedValue1,
          capturedValue2 = foo
        ] in
      }

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  @Test
  func testAlwaysMultilineTrailingCommaBehaviorOverridesMultiElementCollectionTrailingCommas() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .alwaysUsed
    configuration.multiElementCollectionTrailingCommas = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }

  @Test
  func testNeverTrailingCommasInMultilineListsOverridesMultiElementCollectionTrailingCommas() {
    let input =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3,
      ]

      """

    let expected =
      """
      let MyCollection = [
        "a": 1,
        "b": 2,
        "c": 3
      ]

      """

    var configuration = Configuration.forTesting
    configuration.multilineTrailingCommaBehavior = .neverUsed
    configuration.multiElementCollectionTrailingCommas = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: configuration)
  }
}
