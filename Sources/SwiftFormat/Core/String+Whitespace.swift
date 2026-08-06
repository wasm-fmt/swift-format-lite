private extension Unicode.Scalar {
  var isSwiftFormatWhitespaceAndNewline: Bool {
    properties.isWhitespace || value == 0x200B
  }

  var isSwiftFormatNewline: Bool {
    switch value {
    case 0x000A...0x000D, 0x0085, 0x2028, 0x2029:
      return true
    default:
      return false
    }
  }

  var isSwiftFormatHorizontalWhitespace: Bool {
    isSwiftFormatWhitespaceAndNewline && !isSwiftFormatNewline
  }
}

extension StringProtocol {
  func trimmingSwiftFormatHorizontalWhitespace() -> String {
    trimmingSwiftFormatScalars(where: \.isSwiftFormatHorizontalWhitespace)
  }

  func trimmingSwiftFormatWhitespaceAndNewlines() -> String {
    trimmingSwiftFormatScalars(where: \.isSwiftFormatWhitespaceAndNewline)
  }

  func trimmingSwiftFormatSpaces() -> String {
    trimmingSwiftFormatScalars { $0.value == 0x0020 }
  }

  private func trimmingSwiftFormatScalars(
    where shouldTrim: (Unicode.Scalar) -> Bool
  ) -> String {
    let string = String(self)
    let scalars = string.unicodeScalars

    var lowerBound = scalars.startIndex
    while lowerBound != scalars.endIndex && shouldTrim(scalars[lowerBound]) {
      scalars.formIndex(after: &lowerBound)
    }

    var upperBound = scalars.endIndex
    while lowerBound != upperBound {
      let previousIndex = scalars.index(before: upperBound)
      guard shouldTrim(scalars[previousIndex]) else {
        break
      }
      upperBound = previousIndex
    }

    return String(scalars[lowerBound..<upperBound])
  }
}

extension String {
  var swiftFormatTrailingWhitespaceStart: Index? {
    let scalars = unicodeScalars
    var upperBound = scalars.endIndex
    while upperBound != scalars.startIndex {
      let previousIndex = scalars.index(before: upperBound)
      guard scalars[previousIndex].isSwiftFormatHorizontalWhitespace else {
        return upperBound
      }
      upperBound = previousIndex
    }
    return nil
  }
}
