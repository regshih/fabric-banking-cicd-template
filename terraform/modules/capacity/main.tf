data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_fabric_capacity" "this" {
  name                   = var.capacity_name
  resource_group_name    = data.azurerm_resource_group.this.name
  location               = var.location
  administration_members = var.administration_members

  sku {
    name = var.sku_name
    tier = "Fabric"
  }

  tags = var.tags
}
