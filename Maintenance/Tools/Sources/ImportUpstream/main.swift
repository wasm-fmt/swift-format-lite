import MaintenanceCore

runMaintenanceMain(command: "import-upstream") {
  let arguments = try ToolArguments.parse(
    command: "Maintenance/import-upstream",
    valueOption: "--output",
    valueRequired: true
  )
  guard let outputRoot = arguments.value else {
    throw MaintenanceError("missing --output")
  }
  try ImportUpstreamTool.run(
    projectRoot: arguments.projectRoot,
    outputRoot: outputRoot
  )
}
