# EU Network Setup
# Virtual Networks
resource "azurerm_virtual_network" "eu_vnet" {
  name                = "${var.name_prefix}${var.eu_vnet_name}"
  address_space       = var.eu_vnet_address_space
  location            = azurerm_resource_group.eu.location
  resource_group_name = azurerm_resource_group.eu.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.name_prefix}${var.eu_subnet_name}"
  resource_group_name  = azurerm_resource_group.eu.name
  virtual_network_name = azurerm_virtual_network.eu_vnet.name
  address_prefixes     = var.eu_subnet_address_prefix
}
# Define the Private Endpoint
resource "azurerm_private_endpoint" "file_share_private_endpoint" {
  name                = "${var.name_prefix}file_share_pe"
  location            = azurerm_resource_group.eu.location
  resource_group_name = azurerm_resource_group.eu.name
  subnet_id           = azurerm_subnet.subnet.id

  private_dns_zone_group {
    name                 = "add_to_azure_private_dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_account_dns_zone.id]
  }

  private_service_connection {
    name                           = "${var.name_prefix}file_share_connection"
    private_connection_resource_id = azurerm_storage_account.eu_storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

# US Network Setup
# Virtual Networks
resource "azurerm_virtual_network" "us_vnet" {
  name                = "${var.name_prefix}${var.us_vnet_name}"
  address_space       = var.us_vnet_address_space
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name
}

# Subnet
resource "azurerm_subnet" "us_subnet" {
  name                 = "${var.name_prefix}${var.eu_subnet_name}"
  resource_group_name  = azurerm_resource_group.us.name
  virtual_network_name = azurerm_virtual_network.us_vnet.name
  address_prefixes     = var.us_subnet_address_prefix
}


# Define the Network Security Group
resource "azurerm_network_security_group" "us_nsg" {
  name                = "us-nsg"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Define the Network Interface 
resource "azurerm_network_interface" "us_vm_nic" {
  name                = "us-vm-nic"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.us_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# Connect the security group to the network interface
resource "azurerm_subnet_network_security_group_association" "us_subnet_nsg" {
  subnet_id                 = azurerm_subnet.us_subnet.id
  network_security_group_id = azurerm_network_security_group.us_nsg.id
}

# VNet Peering from EU to US
resource "azurerm_virtual_network_peering" "vnetEU-to-vnetUS" {
  name                         = "${var.name_prefix}-EU-to-US"
  resource_group_name          = azurerm_resource_group.eu.name
  virtual_network_name         = azurerm_virtual_network.eu_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.us_vnet.id
  allow_virtual_network_access = true
}

# VNet Peering from US to EU
resource "azurerm_virtual_network_peering" "vnetUS-to-vnetEU" {
  name                         = "${var.name_prefix}-US-to-EU"
  resource_group_name          = azurerm_resource_group.us.name
  virtual_network_name         = azurerm_virtual_network.us_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.eu_vnet.id
  allow_virtual_network_access = true
}