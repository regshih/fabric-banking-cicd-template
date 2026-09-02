variable "subscription_id" {
  description = "Azure subscription used for the Terraform state backend."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for the state backend."
  type        = string
  default     = "westus3"
}

variable "state_resource_group_name" {
  description = "Resource group for Terraform remote state."
  type        = string
  default     = "rg-fabric-banking-tfstate"
}

variable "state_storage_account_name" {
  description = "Globally unique storage account name for Terraform state."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.state_storage_account_name))
    error_message = "Storage account names must contain 3-24 lowercase letters or digits."
  }
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "platform-team"
}

variable "resource_prefix" {
  description = "Lowercase prefix used for resource groups, identities, and tags."
  type        = string
  default     = "fabric-banking"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,30}$", var.resource_prefix))
    error_message = "resource_prefix must contain 3-30 lowercase letters, digits, or hyphens."
  }
}
