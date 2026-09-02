data "azuread_client_config" "current" {}

locals {
  tags = {
    environment         = "shared"
    workload            = var.resource_prefix
    owner               = var.owner
    data-classification = "synthetic"
    managed-by          = "terraform"
  }

  identities = {
    plan = {
      display_name = "sp-${var.resource_prefix}-plan"
      description  = "Read-only Terraform planning identity for the Fabric banking POC."
    }
    apply = {
      display_name = "sp-${var.resource_prefix}-apply"
      description  = "Terraform apply identity scoped to the POC resource groups."
    }
    content = {
      display_name = "sp-${var.resource_prefix}-content"
      description  = "Fabric content deployment and promotion identity."
    }
  }
}

resource "azurerm_resource_group" "state" {
  name     = var.state_resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  #checkov:skip=CKV_AZURE_59:Public blob access is explicitly disabled with allow_nested_items_to_be_public; this is a provider-v4 compatibility false positive.
  #checkov:skip=CKV_AZURE_33:The account has no queue workload; Azure Monitor diagnostics should be enabled centrally if queues are added.
  #checkov:skip=CKV2_AZURE_33:Microsoft-hosted Azure Pipelines agents require the state endpoint to remain reachable; OAuth-only access and no shared keys constrain access.
  #checkov:skip=CKV2_AZURE_1:Platform-managed encryption is proportionate for synthetic POC state; use a CMK and Key Vault for regulated production state.
  name                            = var.state_storage_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "state" {
  #checkov:skip=CKV2_AZURE_21:Read logging is intentionally deferred to the tenant-wide diagnostic policy; state reads are audited by Azure control-plane logs.
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_resource_group" "environment" {
  for_each = toset(["dev", "prod"])

  name     = "rg-${var.resource_prefix}-${each.key}-${var.location}"
  location = var.location
  tags = merge(local.tags, {
    environment = each.key
  })
}

resource "azuread_group" "fabric_admins" {
  display_name            = "FabricAdmins"
  description             = "Administrators for the Fabric banking CI/CD POC."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  owners                  = [data.azuread_client_config.current.object_id]
  members                 = [data.azuread_client_config.current.object_id]
}

resource "azuread_group" "fabric_developers" {
  display_name            = "FabricDevelopers"
  description             = "Developers for the Fabric banking CI/CD POC."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  owners                  = [data.azuread_client_config.current.object_id]
}

resource "azuread_group" "fabric_automation" {
  display_name            = "FabricAutomation"
  description             = "Service principals allowed to run Fabric banking CI/CD automation."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  owners                  = [data.azuread_client_config.current.object_id]
  members                 = [for principal in azuread_service_principal.pipeline : principal.object_id]
}

resource "azuread_application" "pipeline" {
  for_each = local.identities

  display_name     = each.value.display_name
  description      = each.value.description
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "pipeline" {
  for_each = azuread_application.pipeline

  client_id                    = each.value.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "state_plan_contributor" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.pipeline["plan"].object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "state_bootstrap_contributor" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "state_apply_contributor" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.pipeline["apply"].object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "environment_plan_reader" {
  for_each = azurerm_resource_group.environment

  scope                = each.value.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.pipeline["plan"].object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "environment_content_reader" {
  for_each = azurerm_resource_group.environment

  scope                = each.value.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.pipeline["content"].object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "environment_apply_contributor" {
  for_each = azurerm_resource_group.environment

  scope                = each.value.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.pipeline["apply"].object_id
  principal_type       = "ServicePrincipal"
}
