// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SwiftFormatLiteMaintenance",
  platforms: [
    .macOS("13.0")
  ],
  products: [
    .executable(name: "import-upstream", targets: ["ImportUpstream"]),
    .executable(name: "generate-rules", targets: ["GenerateRules"]),
    .executable(name: "audit", targets: ["Audit"]),
    .executable(name: "sync-upstream", targets: ["SyncUpstream"]),
  ],
  targets: [
    .target(name: "MaintenanceCore"),
    .executableTarget(
      name: "ImportUpstream",
      dependencies: ["MaintenanceCore"]
    ),
    .executableTarget(
      name: "GenerateRules",
      dependencies: ["MaintenanceCore"]
    ),
    .executableTarget(
      name: "Audit",
      dependencies: ["MaintenanceCore"]
    ),
    .executableTarget(
      name: "SyncUpstream",
      dependencies: ["MaintenanceCore"]
    ),
  ],
  swiftLanguageModes: [.v5]
)
