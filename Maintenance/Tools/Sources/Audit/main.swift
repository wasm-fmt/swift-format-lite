import MaintenanceCore

runMaintenanceMain(command: "audit") {
  let arguments = try ToolArguments.parse(
    command: "Maintenance/audit",
    valueOption: "--candidate"
  )
  try AuditTool.run(
    projectRoot: arguments.projectRoot,
    candidateRoot: arguments.value
  )
}
