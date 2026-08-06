import MaintenanceCore

runMaintenanceMain(command: "generate-rules") {
  let arguments = try ToolArguments.parse(
    command: "Maintenance/generate-rules",
    valueOption: "--output",
    valueRequired: true
  )
  guard let outputRoot = arguments.value else {
    throw MaintenanceError("missing --output")
  }
  try GenerateRulesTool.run(
    projectRoot: arguments.projectRoot,
    outputRoot: outputRoot
  )
}
