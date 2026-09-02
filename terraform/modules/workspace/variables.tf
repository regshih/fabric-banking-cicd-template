variable "display_name" {
  description = "Fabric workspace display name."
  type        = string
}

variable "description" {
  description = "Fabric workspace description."
  type        = string
}

variable "capacity_id" {
  description = "Fabric capacity GUID. It is supplied explicitly so read-only plan identities do not need capacity-admin discovery permissions."
  type        = string
}

variable "role_assignments" {
  description = "Workspace role assignments keyed by a stable logical name."
  type = map(object({
    principal_id   = string
    principal_type = string
    role           = string
  }))

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      contains(["Group", "ServicePrincipal", "ServicePrincipalProfile", "User"], assignment.principal_type) &&
      contains(["Admin", "Member", "Contributor", "Viewer"], assignment.role)
    ])
    error_message = "Each role assignment must use a supported Fabric principal type and workspace role."
  }
}
