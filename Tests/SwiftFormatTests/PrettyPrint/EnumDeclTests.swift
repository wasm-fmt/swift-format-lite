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
final class EnumDeclTests: PrettyPrintTestCase {
  @Test
  func testBasicEnumDeclarations() {
    let input =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyLongerEnum {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum
        MyLongerEnum
      {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  @Test
  func testMixedEnumCaseStyles_noPackArguments() {
    let input =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth, fifth
        case sixth(Int)
        case seventh(a: Int, b: Bool, c: Double)
      }
      """

    let expected =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth,
          fifth
        case sixth(Int)
        case seventh(
          a: Int,
          b: Bool,
          c: Double
        )
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test
  func testMixedEnumCaseStyles_packArguments() {
    let input =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth, fifth
        case sixth(Int)
        case seventh(a: Int, b: Bool, c: Double)
      }
      """

    let expected =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth,
          fifth
        case sixth(Int)
        case seventh(
          a: Int, b: Bool, c: Double)
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 31, configuration: config)
  }

  @Test
  func testIndirectEnum() {
    let input =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }
      """

    let expected =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  @Test
  func testGenericEnumDeclarations() {
    let input =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<One, Two, Three, Four> {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<
        One, Two, Three, Four
      > {
        case firstCase
        case secondCase
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test
  func testEnumInheritance() {
    let input =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo, ProtoThree {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo,
        ProtoThree
      {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  @Test
  func testEnumWhereClause() {
    let input =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where
        S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  @Test
  func testEnumWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where
        S: Collection,
        T: ReallyLongEnumName,
        U: AnotherLongEnum,
        W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test
  func testEnumWhereClauseWithInheritance() {
    let input =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongEnumName, U: LongerEnumName, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection, T: Protocol, T: ReallyLongEnumName,
        U: LongerEnumName, W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  @Test
  func testEnumWhereClauseWithInheritance_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongEnumName, U: LongerEnumName, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongEnumName,
        U: LongerEnumName,
        W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  @Test
  func testEnumAttributes() {
    let input =
      """
      @dynamicMemberLookup public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public enum MyEnum {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public enum MyEnum {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 55)
  }

  @Test
  func testEnumFullWrap() {
    let input =
      """
      public enum MyEnum<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        case firstCase
        let B: Double
      }
      """

    let expected =

      """
      public enum MyEnum<
        BaseCollection, SecondCollection
      >: MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection, BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test
  func testEnumFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      public enum MyEnum<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        case firstCase
        let B: Double
      }
      """

    let expected =

      """
      public enum MyEnum<
        BaseCollection, SecondCollection
      >: MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection,
        BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  @Test
  func testEmptyEnum() {
    let input = "enum Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      enum Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 10)
  }

  @Test
  func testEmptyEnumWithComment() {
    let input = """
      enum Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test
  func testOneMemberEnum() {
    let input = "enum Foo { var bar: Int }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  @Test
  func testEnumWithPrioritizeKeepingFunctionOutputTogetherFlag() {
    let input = """
      enum Error {
        case alreadyOpen(Int)
      }

      """
    var config = Configuration.forTesting
    config.prioritizeKeepingFunctionOutputTogether = true
    assertPrettyPrintEqual(input: input, expected: input, linelength: 50, configuration: config)
  }
}
