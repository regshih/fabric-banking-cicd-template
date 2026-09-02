variable "workspace_id" {
  description = "Fabric workspace ID."
  type        = string
}

variable "organization_name" {
  description = "Azure DevOps organization name, without URL."
  type        = string
}

variable "project_name" {
  description = "Azure DevOps project name."
  type        = string
}

variable "repository_name" {
  description = "Azure DevOps repository name."
  type        = string
}

variable "branch_name" {
  description = "Concrete branch connected to the workspace."
  type        = string

  validation {
    condition     = !strcontains(var.branch_name, "*")
    error_message = "Fabric Git Integration requires a concrete branch name; wildcards are not supported."
  }
}

variable "directory_name" {
  description = "Repository directory synchronized with Fabric."
  type        = string
  default     = "/fabric-items"

  validation {
    condition     = startswith(var.directory_name, "/")
    error_message = "directory_name must begin with '/'."
  }
}

variable "connection_id" {
  description = "Fabric configured connection ID used by service-principal Git integration."
  type        = string
  sensitive   = true
}
