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

@_spi(Rules) @_spi(Testing) import SwiftFormat
import SwiftOperators
import SwiftParser
import SwiftSyntax
import Testing

class LintOrFormatRuleTestCase {
  /// Asserts that applying a formatter rule to the provided input produces the expected output
  /// and finding specifications.
  func assertFormatting(
    _ formatType: SyntaxFormatRule.Type,
    input: String,
    expected: String,
    findings: [FindingSpec] = [],
    configuration: Configuration? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    let markedInput = MarkedText(textWithMarkers: input)
    let originalSource = markedInput.textWithoutMarkers
    let sourceFileSyntax = try parseSource(originalSource)

    var emittedFindings = [Finding]()
    let configuration = configuration ?? Configuration.forTesting(enabledRule: formatType.ruleName)
    let context = Context(
      configuration: configuration,
      operatorTable: .standardOperators,
      findingConsumer: { emittedFindings.append($0) },
      fileName: "test.swift",
      selection: .infinite,
      sourceFileSyntax: sourceFileSyntax,
      source: originalSource,
      ruleNameCache: ruleNameCache
    )

    let formatter = formatType.init(context: context)
    let actual = formatter.visit(sourceFileSyntax)
    #expect("\(actual)" == expected)

    assertFindings(
      expected: findings,
      markerLocations: markedInput.markers,
      emittedFindings: emittedFindings,
      context: context
    )

    // Verify that the pretty printer can consume the transformed tree and preserve its
    // whitespace-insensitive syntax.
    let prettyPrintedSource = PrettyPrinter(
      context: context,
      source: originalSource,
      node: Syntax(actual),
      whitespaceOnly: false
    ).prettyPrint()
    let prettyPrintedTree = try parseSource(prettyPrintedSource)
    #expect(
      whitespaceInsensitiveText(of: actual) == whitespaceInsensitiveText(of: prettyPrintedTree),
      Comment(rawValue: "After pretty-printing and removing fluid whitespace, the files did not match")
    )
  }

  private func parseSource(_ source: String) throws -> SourceFileSyntax {
    var source = source
    let tree = source.withUTF8 { sourceBytes in
      Parser.parse(source: sourceBytes)
    }
    guard let sourceFile = try OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)
    else {
      throw ParseError.invalidSource
    }
    return sourceFile
  }

  private func assertFindings(
    expected specs: [FindingSpec],
    markerLocations: [String: Int],
    emittedFindings: [Finding],
    context: Context
  ) {
    var emittedFindings = emittedFindings

    for spec in specs {
      guard let utf8Offset = markerLocations[spec.marker] else {
        Issue.record(Comment(rawValue: "Marker '\(spec.marker)' was not found in the input"))
        continue
      }

      let markerLocation = context.sourceLocationConverter.location(
        for: AbsolutePosition(utf8Offset: utf8Offset)
      )
      guard let index = emittedFindings.firstIndex(where: {
        markerLocation.line == $0.location?.line && markerLocation.column == $0.location?.column
      }) else {
        let message =
          "Finding '\(spec.message)' was not emitted at marker '\(spec.marker)' "
          + "(line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset))"
        Issue.record(Comment(rawValue: message))
        continue
      }

      let matchedFinding = emittedFindings.remove(at: index)
      let findingMessage =
        "Finding emitted at marker '\(spec.marker)' "
        + "(line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset)) "
        + "had the wrong message"
      #expect(matchedFinding.message.text == spec.message, Comment(rawValue: findingMessage))

      var emittedNotes = matchedFinding.notes
      for noteSpec in spec.notes {
        guard let noteOffset = markerLocations[noteSpec.marker] else {
          Issue.record(Comment(rawValue: "Marker '\(noteSpec.marker)' was not found in the input"))
          continue
        }

        let noteLocation = context.sourceLocationConverter.location(
          for: AbsolutePosition(utf8Offset: noteOffset)
        )
        guard let noteIndex = emittedNotes.firstIndex(where: {
          noteLocation.line == $0.location?.line && noteLocation.column == $0.location?.column
        }) else {
          let message =
            "Note '\(noteSpec.message)' was not emitted at marker '\(noteSpec.marker)' "
            + "(line:col \(noteLocation.line):\(noteLocation.column), offset \(noteOffset))"
          Issue.record(Comment(rawValue: message))
          continue
        }

        let matchedNote = emittedNotes.remove(at: noteIndex)
        let noteMessage =
          "Note emitted at marker '\(noteSpec.marker)' "
          + "(line:col \(noteLocation.line):\(noteLocation.column), offset \(noteOffset)) "
          + "had the wrong message"
        #expect(matchedNote.message.text == noteSpec.message, Comment(rawValue: noteMessage))
      }

      for note in emittedNotes {
        let locationString: String
        if let location = note.location {
          locationString = "line:col \(location.line):\(location.column)"
        } else {
          locationString = "no location provided"
        }
        Issue.record(Comment(rawValue: "Unexpected note '\(note.message)' was emitted (\(locationString))"))
      }
    }

    for finding in emittedFindings {
      let locationString: String
      if let location = finding.location {
        locationString = "line:col \(location.line):\(location.column)"
      } else {
        locationString = "no location provided"
      }
      Issue.record(Comment(rawValue: "Unexpected finding '\(finding.message)' was emitted (\(locationString))"))
    }
  }

  /// Returns a string containing a whitespace-insensitive representation of the given source file.
  private func whitespaceInsensitiveText(of file: SourceFileSyntax) -> String {
    var result = ""
    for token in file.tokens(viewMode: .sourceAccurate) {
      appendNonspaceTrivia(token.leadingTrivia, to: &result)
      result.append(token.text)
      appendNonspaceTrivia(token.trailingTrivia, to: &result)
    }
    return result
  }

  /// Appends any non-whitespace trivia pieces from the given trivia collection to the output.
  private func appendNonspaceTrivia(_ trivia: Trivia, to string: inout String) {
    for piece in trivia {
      switch piece {
      case .carriageReturnLineFeeds, .carriageReturns, .formfeeds, .newlines, .spaces, .tabs:
        break
      case .lineComment(let comment), .docLineComment(let comment):
        if let lastNonWhitespaceIndex = comment.lastIndex(where: { !$0.isWhitespace }) {
          string.append(contentsOf: comment[...lastNonWhitespaceIndex])
        } else {
          string.append(comment)
        }
      default:
        piece.write(to: &string)
      }
    }
  }
}

private enum ParseError: Error {
  case invalidSource
}
