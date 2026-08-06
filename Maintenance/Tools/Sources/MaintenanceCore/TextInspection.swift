import Foundation

struct TextHit {
  let path: String
  let line: Int
  let text: String

  var description: String {
    "\(path):\(line):\(text)"
  }
}

func regexCaptures(
  pattern: String,
  in text: String,
  options: NSRegularExpression.Options = []
) throws -> [[String]] {
  let expression: NSRegularExpression
  do {
    expression = try NSRegularExpression(pattern: pattern, options: options)
  } catch {
    throw MaintenanceError("invalid maintenance regex '\(pattern)': \(error.localizedDescription)")
  }

  let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
  return expression.matches(in: text, range: fullRange).map { match in
    (1..<match.numberOfRanges).map { index in
      let range = match.range(at: index)
      guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else {
        return ""
      }
      return String(text[swiftRange])
    }
  }
}

func firstRegexCapture(pattern: String, in text: String) throws -> String? {
  try regexCaptures(pattern: pattern, in: text).first?.first
}

func testMethodNames(in text: String) throws -> [String] {
  try regexCaptures(
    pattern: #"^  func (test[A-Za-z0-9_]*)\("#,
    in: text,
    options: [.anchorsMatchLines]
  ).compactMap(\.first)
}

func scanTextFiles(
  root: URL,
  paths: [String],
  patterns: [String]
) throws -> [TextHit] {
  let expressions = try patterns.map { pattern in
    do {
      return try NSRegularExpression(pattern: pattern)
    } catch {
      throw MaintenanceError(
        "invalid audit regex '\(pattern)': \(error.localizedDescription)"
      )
    }
  }

  var hits: [TextHit] = []
  for path in paths.sorted() {
    let text = try FileSystem.readText(relativeURL(path, under: root))
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    for (lineIndex, lineSlice) in lines.enumerated() {
      let line = String(lineSlice)
      let range = NSRange(line.startIndex..<line.endIndex, in: line)
      if expressions.contains(where: { !$0.matches(in: line, range: range).isEmpty }) {
        hits.append(TextHit(path: path, line: lineIndex + 1, text: line))
      }
    }
  }
  return hits
}

func exactLineCount(_ line: String, in text: String) -> Int {
  text.split(separator: "\n", omittingEmptySubsequences: false)
    .lazy
    .map(String.init)
    .filter { $0 == line }
    .count
}
