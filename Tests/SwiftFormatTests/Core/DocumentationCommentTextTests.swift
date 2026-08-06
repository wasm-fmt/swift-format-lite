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

@_spi(Testing) import SwiftFormat
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

@Suite
final class DocumentationCommentTextTests {
  @Test
  func testSimpleDocLineComment() throws {
    let decl: DeclSyntax = """
      /// A simple doc comment.
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .line)
    #expect(commentText.text == """
      A simple doc comment.

      """)
  }

  @Test
  func testOneLineDocBlockComment() throws {
    let decl: DeclSyntax = """
      /** A simple doc comment. */
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(commentText.text == """
      A simple doc comment.\u{0020}

      """)
  }

  @Test
  func testDocBlockCommentWithASCIIArt() throws {
    let decl: DeclSyntax = """
      /**
       * A simple doc comment.
       */
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(commentText.text == """
      A simple doc comment.

      """)
  }

  @Test
  func testIndentedDocBlockCommentWithASCIIArt() throws {
    let decl: DeclSyntax = """
        /**
         * A simple doc comment.
         */
        func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(commentText.text == """
      A simple doc comment.

      """)
  }

  @Test
  func testDocBlockCommentWithoutASCIIArt() throws {
    let decl: DeclSyntax = """
      /**
         A simple doc comment.
       */
      func f() {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(commentText.text == """
      A simple doc comment.

      """)
  }

  @Test
  func testMultilineDocLineComment() throws {
    let decl: DeclSyntax = """
      /// A doc comment.
      ///
      /// This is a longer paragraph,
      /// containing more detail.
      ///
      /// - Parameter x: A parameter.
      /// - Returns: A value.
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .line)
    #expect(commentText.text == """
      A doc comment.

      This is a longer paragraph,
      containing more detail.

      - Parameter x: A parameter.
      - Returns: A value.

      """)
  }

  @Test
  func testDocLineCommentStopsAtBlankLine() throws {
    let decl: DeclSyntax = """
      /// This should not be part of the comment.

      /// A doc comment.
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .line)
    #expect(commentText.text == """
      A doc comment.

      """)
  }

  @Test
  func testDocBlockCommentStopsAtBlankLine() throws {
    let decl: DeclSyntax = """
      /** This should not be part of the comment. */

      /**
       * This is part of the comment.
       */
      /** so is this */
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .block)
    #expect(commentText.text == """
      This is part of the comment.
       so is this\u{0020}

      """)
  }

  @Test
  func testDocCommentHasMixedIntroducers() throws {
    let decl: DeclSyntax = """
      /// This is part of the comment.
      /** This is too. */
      func f(x: Int) -> Int {}
      """
    let commentText = try #require(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    #expect(commentText.introducer == .mixed)
    #expect(commentText.text == """
      This is part of the comment.
      This is too.\u{0020}

      """)
  }

  @Test
  func testNilIfNoComment() throws {
    let decl: DeclSyntax = """
      func f(x: Int) -> Int {}
      """
    #expect(DocumentationCommentText(extractedFrom: decl.leadingTrivia) == nil)
  }
}
