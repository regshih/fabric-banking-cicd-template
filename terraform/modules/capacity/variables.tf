variable "resource_group_name" {
  description = "Resource group that owns the Fabric capacity."
  type        = string
}

variable "location" {
  description = "Azure region for the resource group and capacity."
  type        = string
}

variable "capacity_name" {
  description = "Exact Microsoft Fabric capacity resource name."
  type        = string
}

variable "sku_name" {
  description = "Fabric capacity SKU."
  type        = string
  default     = "F2"

  validation {
    condition     = can(regex("^F[0-9]+$", var.sku_name))
    error_message = "sku_name must be a Fabric F SKU such as F2 or F4."
  }
}

variable "administration_members" {
  description = "Entra object IDs or UPNs that administer the capacity."
  type        = set(string)
  nullable    = false

  validation {
    condition     = length(var.administration_members) > 0
    error_message = "At least one capacity administrator is required."
  }
}

variable "tags" {
  description = "Tags applied to Azure resources."
  type        = map(string)
}
