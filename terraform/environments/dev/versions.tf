terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.3"
    }
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 1.12"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "fabric" {
  tenant_id = var.tenant_id
}
