output "git_connection_state" {
  description = "Fabric workspace Git connection state."
  value       = fabric_workspace_git.this.git_connection_state
}

output "last_sync_time" {
  description = "Last successful Fabric Git sync time."
  value       = fabric_workspace_git.this.git_sync_details.last_sync_time
}
