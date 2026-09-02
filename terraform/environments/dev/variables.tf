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
  description = "Fabric service GUID for the Dev capacity."
  type        = string
}

variable "resource_group_name" {
  description = "Existing Azure resource group for the Dev environment."
  type        = string
}

variable "capacity_name" {
  description = "Globally unique Azure Fabric capacity resource name without hyphens."
  type        = string
}

variable "state_resource_group_name" {
  description = "Resource group containing the Terraform state storage account."
  type        = string
}

variable "state_storage_account_name" {
  description = "Terraform state storage account name."
  type        = string
}

variable "enable_git_integration" {
  description = "Create new Dev and Feature workspace Git connections. Leave false when connections already exist because the provider cannot import them."
  type        = bool
  default     = false
}

variable "azure_devops_organization" {
  description = "Azure DevOps organization name."
  type        = string
  default     = ""
}

variable "azure_devops_project" {
  description = "Azure DevOps project name."
  type        = string
  default     = ""
}

variable "azure_devops_repository" {
  description = "Azure DevOps repository name."
  type        = string
  default     = "fabric-banking-cicd-template"
}

variable "fabric_git_connection_id" {
  description = "Configured Fabric connection ID for Azure DevOps Git integration."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_feature_workspace" {
  description = "Create the optional Fabric-Feature workspace."
  type        = bool
  default     = false
}

variable "feature_branch" {
  description = "Concrete feature branch connected to Fabric-Feature."
  type        = string
  default     = "feature/banking-demo"

  validation {
    condition     = !strcontains(var.feature_branch, "*")
    error_message = "feature_branch must be a concrete branch, not feature/*."
  }
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

variable "enable_private_agent" {
  description = "Provision the private Azure Pipelines agent and state private endpoint."
  type        = bool
  default     = false
}

variable "agent_ssh_public_key" {
  description = "SSH public key used for break-glass access to the private build agent."
  type        = string
  default     = ""
}

variable "agent_vm_size" {
  description = "VM size for the private Azure Pipelines agent."
  type        = string
  default     = "Standard_D2ls_v6"
}
