variable "display_name" {
  description = "Fabric deployment pipeline display name."
  type        = string
}

variable "dev_workspace_id" {
  description = "Workspace assigned to the Dev stage."
  type        = string
}

variable "prod_workspace_id" {
  description = "Workspace assigned to the Prod stage."
  type        = string
}

variable "administrator_principal_ids" {
  description = "Service principals or groups granted deployment pipeline Admin."
  type        = set(string)
  default     = []
}
