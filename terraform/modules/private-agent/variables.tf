variable "resource_group_name" {
  description = "Resource group for the private Azure Pipelines agent."
  type        = string
}

variable "location" {
  description = "Azure region for agent resources."
  type        = string
}

variable "storage_account_id" {
  description = "Terraform state storage account resource ID."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key retained for break-glass access through approved private connectivity."
  type        = string

  validation {
    condition     = startswith(var.ssh_public_key, "ssh-")
    error_message = "ssh_public_key must be an OpenSSH public key."
  }
}

variable "vm_size" {
  description = "Azure VM size for the build agent."
  type        = string
  default     = "Standard_D2ls_v6"
}

variable "tags" {
  description = "Tags applied to agent resources."
  type        = map(string)
  default     = {}
}
