//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License 2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
import Foundation
import SwiftFormat
import Testing

@Suite
struct ConfigurationTests {
  @Test
  func testDefaultConfigurationIsSameAsEmptyDecode() throws {
    // Since we don't use the synthesized `init(from: Decoder)` and allow fields
    // to be missing, we provide defaults there as well as in the property
    // declarations themselves. This test ensures that creating a default-
    // initialized `Configuration` is identical to decoding one from an empty
    // JSON input, which verifies that those defaults are always in sync.
    let defaultInitConfig = Configuration()

    let emptyDictionaryData = try #require("{}\n".data(using: .utf8))
    let jsonDecoder = JSONDecoder()
    #if canImport(Darwin) || compiler(>=6)
    jsonDecoder.allowsJSON5 = true
    #endif
    let emptyJSONConfig =
      try jsonDecoder.decode(Configuration.self, from: emptyDictionaryData)

    #expect(defaultInitConfig == emptyJSONConfig)
  }

  @Test
  func testDecodingReflowMultilineStringLiteralsAsString() throws {
    let testCases: [String: Configuration.MultilineStringReflowBehavior] = [
      "never": .never,
      "always": .always,
      "onlyLinesOverLength": .onlyLinesOverLength,
    ]

    for (jsonString, expectedBehavior) in testCases {
      let jsonData = try #require(
        """
          {
              "reflowMultilineStringLiterals": "\(jsonString)"
          }
          """.data(using: .utf8)
      )

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      #expect(config.reflowMultilineStringLiterals == expectedBehavior)
    }
  }

  @Test
  func testDecodingReflowMultilineStringLiteralsAsObject() throws {
    let testCases: [String: Configuration.MultilineStringReflowBehavior] = [
      "{ \"never\": {} }": .never,
      "{ \"always\": {} }": .always,
      "{ \"onlyLinesOverLength\": {} }": .onlyLinesOverLength,
    ]

    for (jsonString, expectedBehavior) in testCases {
      let jsonData = try #require(
        """
          {
              "reflowMultilineStringLiterals": \(jsonString)
          }
          """.data(using: .utf8)
      )

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      #expect(config.reflowMultilineStringLiterals == expectedBehavior)
    }
  }

  @Test
  func testConfigurationWithComments() throws {
    let expected = Configuration()

    let jsonData = try #require(
      """
        {
            // Indicates the configuration schema version.
            "version": 1,
        }
        """.data(using: .utf8)
    )

    let jsonDecoder = JSONDecoder()
    #if canImport(Darwin) || compiler(>=6)
    jsonDecoder.allowsJSON5 = true
    #endif
    let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
    #expect(config == expected)
  }
}
