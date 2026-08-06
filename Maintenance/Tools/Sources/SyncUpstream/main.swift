import MaintenanceCore

runMaintenanceMain(command: "sync-upstream") {
  let arguments = try ToolArguments.parse(
    command: "Maintenance/sync-upstream"
  )
  try SyncUpstreamTool.run(projectRoot: arguments.projectRoot)
}
