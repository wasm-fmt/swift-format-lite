// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swift-format-lite",
  platforms: [
    .macOS("13.0"),
    .iOS("16.0"),
  ],
  products: [
    .library(name: "SwiftFormat", targets: ["SwiftFormat"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/swiftlang/swift-syntax.git",
      revision: "2b59c0c741e9184ab057fd22950b491076d42e91"
    ),
  ],
  targets: [
    .target(
      name: "SwiftFormat",
      dependencies: [
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatTests",
      dependencies: [
        "SwiftFormat",
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
      ]
    ),
  ],
  swiftLanguageModes: [.v5]
)
