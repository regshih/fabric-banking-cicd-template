output "capacity_arm_id" {
  description = "Azure Resource Manager ID of the Fabric capacity."
  value       = azurerm_fabric_capacity.this.id
}

output "capacity_name" {
  description = "Fabric capacity resource name."
  value       = azurerm_fabric_capacity.this.name
}

output "resource_group_id" {
  description = "Resource group ID."
  value       = data.azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "Resource group name."
  value       = data.azurerm_resource_group.this.name
}
