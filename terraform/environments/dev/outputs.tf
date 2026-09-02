output "resource_group_name" {
  value = module.capacity.resource_group_name
}

output "capacity_name" {
  value = module.capacity.capacity_name
}

output "workspace_id" {
  value = module.workspace.workspace_id
}

output "feature_workspace_id" {
  value = try(module.feature_workspace[0].workspace_id, null)
}

output "git_connection_state" {
  value = try(module.workspace_git[0].git_connection_state, "disabled")
}

output "private_agent" {
  description = "Private Azure Pipelines agent details when enabled."
  value = try({
    vm_name                = module.private_agent[0].vm_name
    principal_id           = module.private_agent[0].principal_id
    private_ip_address     = module.private_agent[0].private_ip_address
    state_private_endpoint = module.private_agent[0].state_private_endpoint_id
  }, null)
}
