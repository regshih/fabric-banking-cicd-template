output "vm_id" {
  description = "Resource ID of the private Azure Pipelines agent VM."
  value       = azurerm_linux_virtual_machine.agent.id
}

output "vm_name" {
  description = "Name of the private Azure Pipelines agent VM."
  value       = azurerm_linux_virtual_machine.agent.name
}

output "principal_id" {
  description = "Object ID of the agent VM system-assigned identity."
  value       = azurerm_linux_virtual_machine.agent.identity[0].principal_id
}

output "private_ip_address" {
  description = "Private IP address of the agent VM."
  value       = azurerm_network_interface.agent.private_ip_address
}

output "state_private_endpoint_id" {
  description = "Resource ID of the Terraform state Blob private endpoint."
  value       = azurerm_private_endpoint.state_blob.id
}
