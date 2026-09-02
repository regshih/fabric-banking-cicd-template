output "state_backend" {
  description = "Values passed to Terraform backend initialization."
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
  }
}

output "fabric_admin_group_id" {
  description = "Object ID of FabricAdmins."
  value       = azuread_group.fabric_admins.object_id
}

output "fabric_developer_group_id" {
  description = "Object ID of FabricDevelopers."
  value       = azuread_group.fabric_developers.object_id
}

output "fabric_automation_group_id" {
  description = "Object ID of the FabricAutomation security group used to scope Fabric tenant settings."
  value       = azuread_group.fabric_automation.object_id
}

output "pipeline_identities" {
  description = "Client and object IDs used to configure Azure DevOps workload identity service connections."
  value = {
    for key, service_principal in azuread_service_principal.pipeline : key => {
      client_id = azuread_application.pipeline[key].client_id
      object_id = service_principal.object_id
    }
  }
}

output "environment_resource_groups" {
  description = "Environment resource groups created during bootstrap."
  value       = { for key, resource_group in azurerm_resource_group.environment : key => resource_group.name }
}
