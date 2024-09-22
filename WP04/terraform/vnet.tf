module "vnet_rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"

  name     = var.vnet_rg_name
  location = var.location

  enable_telemetry = false
}

module "avm-res-network-virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.4.0"
  # insert the 3 required variables here

  resource_group_name = module.vnet_rg.name
  address_space       = [var.vnet_address_space]
  location            = var.location
  name                = var.vnet_name

  subnets = {
    "subnet1" = {
      name           = "subnet1"
      address_prefix = var.vnet_subnet_address_prefix
      network_security_group = {
        id = module.avm-res-network-networksecuritygroup.resource_id
      }
    }
  }

  enable_telemetry = false
}

module "avm-res-network-networksecuritygroup" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.2.0"
  # insert the 3 required variables here

  location            = var.location
  name                = var.nsg_name
  resource_group_name = module.vnet_rg.name

  enable_telemetry = false

  security_rules = {
    "ssh" = {
      name                       = "allow-in-ssh"
      access                     = "Allow"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "22"
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    },
    "rdp" = {
      name                       = "allow-in-rdp"
      access                     = "Allow"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "3389"
      direction                  = "Inbound"
      priority                   = 210
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    },
    "http-8080" = {
      name                       = "allow-in-http-8080"
      access                     = "Allow"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "8080"
      direction                  = "Inbound"
      priority                   = 300
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
  }
}
