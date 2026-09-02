resource "azurerm_virtual_network" "this" {
  name                = "vnet-fabric-cicd-agent-westus3"
  address_space       = ["10.42.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "agent" {
  name                 = "snet-agents"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.42.1.0/24"]
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "snet-private-endpoints"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = ["10.42.2.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_network_security_group" "agent" {
  name                = "nsg-fabric-cicd-agent"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "agent" {
  subnet_id                 = azurerm_subnet.agent.id
  network_security_group_id = azurerm_network_security_group.agent.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.agent.id
}

resource "azurerm_public_ip" "nat" {
  name                = "pip-fabric-cicd-agent-egress"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags

  # The subscription policy stamps an Azure-owned FirstPartyUsage IP tag and
  # normalizes the empty zone list. Neither setting is workload configuration.
  lifecycle {
    ignore_changes = [ip_tags, zones]
  }
}

resource "azurerm_nat_gateway" "this" {
  name                    = "nat-fabric-cicd-agent"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "agent" {
  subnet_id      = azurerm_subnet.agent.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-fabric-cicd-agent"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "state_blob" {
  name                = "pe-${basename(var.storage_account_id)}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-${basename(var.storage_account_id)}-blob"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  tags = var.tags
}

resource "azurerm_network_interface" "agent" {
  name                = "nic-fabric-azdo-agent"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.agent.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "agent" {
  #checkov:skip=CKV_AZURE_50:Azure VM agent operations are required for secure post-provision registration and recovery; no VM extension resources are installed.
  #checkov:skip=CKV_AZURE_178:The SSH public key is injected through a protected pipeline variable and password authentication is explicitly disabled; static analysis cannot resolve the variable value.
  name                            = "vm-fabric-azdo-agent"
  computer_name                   = "fabric-azdo-agent"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = "azdoagent"
  disable_password_authentication = true # pragma: allowlist secret -- control name, not a credential
  network_interface_ids           = [azurerm_network_interface.agent.id]

  admin_ssh_key {
    username   = "azdoagent"
    public_key = var.ssh_public_key
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "osdisk-fabric-azdo-agent"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - ca-certificates
      - curl
      - git
      - jq
      - libicu74
      - python-is-python3
      - python3
      - python3-pip
      - python3-venv
      - unzip
    CLOUD_INIT
  )

  boot_diagnostics {}
  tags = var.tags
}
