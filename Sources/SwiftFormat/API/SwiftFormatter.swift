#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import SwiftOperators
import SwiftSyntax

/// The Lite formatter exposes only an in-memory String-to-String operation.
public final class SwiftFormatter {
  public let configuration: Configuration

  public init(configuration: Configuration = .init()) {
    self.configuration = configuration
  }

  /// Creates a formatter from an in-memory JSON configuration string.
  public convenience init(configurationJSON: String) throws {
    try self.init(configuration: Configuration(data: Data(configurationJSON.utf8)))
  }

  /// Formats one complete Swift source string and returns the formatted source.
  ///
  /// Parsing diagnostics are strict: invalid or incomplete Swift source throws
  /// `SwiftFormatError.fileContainsInvalidSyntax`.
  public func format(_ source: String) throws -> String {
    guard !source.isEmpty else { return "" }

    let sourceFile = try parseAndEmitDiagnostics(
      source: source,
      operatorTable: .standardOperators,
      fileName: "input.swift",
      parsingDiagnosticHandler: { _, _ in }
    )
    let context = Context(
      configuration: configuration,
      operatorTable: .standardOperators,
      findingConsumer: nil,
      fileName: "input.swift",
      selection: .infinite,
      sourceFileSyntax: sourceFile,
      source: source,
      ruleNameCache: ruleNameCache
    )
    let transformedSyntax = FormatPipeline(context: context).rewrite(Syntax(sourceFile))
    let printer = PrettyPrinter(
      context: context,
      source: source,
      node: transformedSyntax,
      whitespaceOnly: false
    )
    return printer.prettyPrint()
  }
}
