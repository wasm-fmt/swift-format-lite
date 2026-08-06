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
@_spi(Rules) @_spi(Testing) import SwiftFormat
import SwiftOperators
import SwiftParser
import SwiftSyntax
import Testing

class PrettyPrintTestCase {
  /// Asserts that the input string, when pretty printed, is equal to the expected string.
  ///
  /// - Parameters:
  ///   - input: The input text to pretty print.
  ///   - expected: The expected pretty-printed output.
  ///   - linelength: The maximum allowed line length of the output.
  ///   - configuration: The formatter configuration.
  ///   - whitespaceOnly: If true, the pretty printer should only apply whitespace changes and omit
  ///     changes that insert or remove non-whitespace characters (like trailing commas).
  ///   - findings: A list of `FindingSpec` values that describe the findings that are expected to
  ///     be emitted. These are currently only checked if `whitespaceOnly` is true.
  final func assertPrettyPrintEqual(
    input: String,
    expected: String,
    linelength: Int,
    configuration: Configuration = Configuration.forTesting,
    whitespaceOnly: Bool = false,
    findings: [FindingSpec] = []
  ) {
    var configuration = configuration
    configuration.lineLength = linelength

    let markedInput = MarkedText(textWithMarkers: input)
    var emittedFindings = [Finding]()

    // Assert that the input, when formatted, is what we expected.
    let (formatted, context) = prettyPrintedSource(
      markedInput.textWithoutMarkers,
      configuration: configuration,
      selection: markedInput.selection,
      whitespaceOnly: whitespaceOnly,
      findingConsumer: { emittedFindings.append($0) }
    )
    assertStringsEqualWithDiff(
      formatted,
      expected,
      "Pretty-printed result was not what was expected"
    )

    // FIXME: It would be nice to check findings when whitespaceOnly == false, but their locations
    // are wrong.
    if whitespaceOnly {
      assertFindings(
        expected: findings,
        markerLocations: markedInput.markers,
        emittedFindings: emittedFindings,
        context: context
      )
    }

    // Idempotency check: Running the formatter multiple times should not change the outcome.
    // Assert that running the formatter again on the previous result keeps it the same.
    // But if we have ranges, they aren't going to be valid for the formatted text.
    if case .infinite = markedInput.selection {
      let (reformatted, _) = prettyPrintedSource(
        formatted,
        configuration: configuration,
        selection: markedInput.selection,
        whitespaceOnly: whitespaceOnly,
        findingConsumer: { _ in }  // Ignore findings during the idempotence check.
      )
      assertStringsEqualWithDiff(
        reformatted,
        formatted,
        "Pretty printer is not idempotent"
      )
    }
  }

  /// Returns the given source code reformatted with the pretty printer.
  private func prettyPrintedSource(
    _ source: String,
    configuration: Configuration,
    selection: Selection,
    whitespaceOnly: Bool,
    findingConsumer: @escaping (Finding) -> Void
  ) -> (String, Context) {
    // Ignore folding errors for unrecognized operators so that we fallback to a reasonable default.
    var source = source
    let parsedSourceFileSyntax = source.withUTF8 { sourceBytes in
      Parser.parse(source: sourceBytes)
    }
    let sourceFileSyntax =
      OperatorTable.standardOperators.foldAll(parsedSourceFileSyntax) { _ in }
        .as(SourceFileSyntax.self)!
    let context = Context(
      configuration: configuration,
      operatorTable: .standardOperators,
      findingConsumer: findingConsumer,
      fileName: "test.swift",
      selection: selection,
      sourceFileSyntax: sourceFileSyntax,
      source: source,
      ruleNameCache: ruleNameCache
    )
    let printer = PrettyPrinter(
      context: context,
      source: source,
      node: Syntax(sourceFileSyntax),
      whitespaceOnly: whitespaceOnly
    )
    return (printer.prettyPrint(), context)
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
        Issue.record("Marker '\(spec.marker)' was not found in the input")
        continue
      }

      let markerLocation = context.sourceLocationConverter.location(
        for: AbsolutePosition(utf8Offset: utf8Offset)
      )
      guard let index = emittedFindings.firstIndex(where: {
        markerLocation.line == $0.location?.line && markerLocation.column == $0.location?.column
      }) else {
        Issue.record(
          Comment(
            rawValue: "Finding '\(spec.message)' was not emitted at marker '\(spec.marker)' "
              + "(line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset))"
          )
        )
        continue
      }

      let matchedFinding = emittedFindings.remove(at: index)
      #expect(
        matchedFinding.message.text == spec.message,
        Comment(
          rawValue: "Finding emitted at marker '\(spec.marker)' "
            + "(line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset)) "
            + "had the wrong message"
        )
      )

      var emittedNotes = matchedFinding.notes
      for noteSpec in spec.notes {
        guard let noteOffset = markerLocations[noteSpec.marker] else {
          Issue.record("Marker '\(noteSpec.marker)' was not found in the input")
          continue
        }

        let noteLocation = context.sourceLocationConverter.location(
          for: AbsolutePosition(utf8Offset: noteOffset)
        )
        guard let noteIndex = emittedNotes.firstIndex(where: {
          noteLocation.line == $0.location?.line && noteLocation.column == $0.location?.column
        }) else {
          Issue.record(
            Comment(
              rawValue: "Note '\(noteSpec.message)' was not emitted at marker '\(noteSpec.marker)' "
                + "(line:col \(noteLocation.line):\(noteLocation.column), offset \(noteOffset))"
            )
          )
          continue
        }

        let matchedNote = emittedNotes.remove(at: noteIndex)
        #expect(
          matchedNote.message.text == noteSpec.message,
          Comment(
            rawValue: "Note emitted at marker '\(noteSpec.marker)' "
              + "(line:col \(noteLocation.line):\(noteLocation.column), offset \(noteOffset)) "
              + "had the wrong message"
          )
        )
      }

      for note in emittedNotes {
        let locationString: String
        if let location = note.location {
          locationString = "line:col \(location.line):\(location.column)"
        } else {
          locationString = "no location provided"
        }
        Issue.record("Unexpected note '\(note.message)' was emitted (\(locationString))")
      }
    }

    for finding in emittedFindings {
      let locationString: String
      if let location = finding.location {
        locationString = "line:col \(location.line):\(location.column)"
      } else {
        locationString = "no location provided"
      }
      Issue.record("Unexpected finding '\(finding.message)' was emitted (\(locationString))")
    }
  }

  /// Asserts that the two strings are equal, providing Unix `diff`-style output if they are not.
  private func assertStringsEqualWithDiff(
    _ actual: String,
    _ expected: String,
    _ message: String = ""
  ) {
    let actualLines = actual.components(separatedBy: .newlines)
    let expectedLines = expected.components(separatedBy: .newlines)
    let difference = actualLines.difference(from: expectedLines)
    guard !difference.isEmpty else { return }

    var result = ""
    var insertions = [Int: String]()
    var removals = [Int: String]()

    for change in difference {
      switch change {
      case .insert(let offset, let element, _):
        insertions[offset] = element
      case .remove(let offset, let element, _):
        removals[offset] = element
      }
    }

    var expectedLine = 0
    var actualLine = 0
    while expectedLine < expectedLines.count || actualLine < actualLines.count {
      if let removal = removals[expectedLine] {
        result += "-\(removal)\n"
        expectedLine += 1
      } else if let insertion = insertions[actualLine] {
        result += "+\(insertion)\n"
        actualLine += 1
      } else {
        result += " \(expectedLines[expectedLine])\n"
        expectedLine += 1
        actualLine += 1
      }
    }

    let failureMessage = "Actual output (+) differed from expected output (-):\n\(result)"
    let fullMessage = message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
    Issue.record(Comment(rawValue: fullMessage))
  }
}
