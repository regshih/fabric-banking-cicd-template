output "workspace_id" {
  description = "Fabric workspace ID."
  value       = fabric_workspace.this.id
}

output "workspace_identity_application_id" {
  description = "Application ID of the system-assigned workspace identity."
  value       = fabric_workspace.this.identity.application_id
}

output "workspace_identity_service_principal_id" {
  description = "Service principal ID of the system-assigned workspace identity."
  value       = fabric_workspace.this.identity.service_principal_id
}
