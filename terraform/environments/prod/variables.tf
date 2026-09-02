variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by Fabric."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westus3"
}

variable "fabric_admin_group_id" {
  description = "Object ID of FabricAdmins."
  type        = string
}

variable "fabric_developer_group_id" {
  description = "Object ID of FabricDevelopers."
  type        = string
}

variable "plan_service_principal_id" {
  description = "Object ID of the Terraform plan service principal."
  type        = string
}

variable "apply_service_principal_id" {
  description = "Object ID of the Terraform apply service principal."
  type        = string
}

variable "content_service_principal_id" {
  description = "Object ID of the Fabric content deployment service principal."
  type        = string
}

variable "capacity_admin_members" {
  description = "Additional capacity administrator object IDs or UPNs."
  type        = set(string)
  default     = []
}

variable "fabric_capacity_id" {
  description = "Fabric service GUID for the Prod capacity."
  type        = string
}

variable "resource_group_name" {
  description = "Existing Azure resource group for the Prod environment."
  type        = string
}

variable "capacity_name" {
  description = "Globally unique Azure Fabric capacity resource name without hyphens."
  type        = string
}

variable "dev_workspace_id" {
  description = "Existing Dev workspace ID assigned to the first deployment stage. Passing the ID avoids broad capacity-discovery permissions for the plan identity."
  type        = string
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "platform-team"
}

variable "workload_name" {
  description = "Workload tag value."
  type        = string
  default     = "fabric-banking-cicd"
}
