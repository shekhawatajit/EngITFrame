provider "azurerm" {
  subscription_id = var.az_subscription_id
  features {}
}

# Resource Groups
resource "azurerm_resource_group" "us" {
  name     = var.us_resource_group_name
  location = var.us_resource_location
}

resource "azurerm_resource_group" "eu" {
  name     = var.eu_resource_group_name
  location = var.eu_resource_location
}

# Virtual Networks
resource "azurerm_virtual_network" "eu_vnet" {
  name                = var.eu_vnet_name
  address_space       = var.eu_vnet_address_space
  location            = azurerm_resource_group.eu.location
  resource_group_name = azurerm_resource_group.eu.name
}

resource "azurerm_virtual_network" "us_vnet" {
  name                = var.us_vnet_name
  address_space       = var.us_vnet_address_space
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name
}

# VNet Peering from EU to US
resource "azurerm_virtual_network_peering" "vnetEU-to-vnetUS" {
  name                      = "vnetEU-to-vnetUS"
  resource_group_name       = azurerm_resource_group.eu.name
  virtual_network_name      = azurerm_virtual_network.eu_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.us_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet Peering from US to EU
resource "azurerm_virtual_network_peering" "vnetUS-to-vnetEU" {
  name                      = "vnetUS-to-vnetEU"
  resource_group_name       = azurerm_resource_group.us.name
  virtual_network_name      = azurerm_virtual_network.us_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.eu_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}


# Storage Account and File Share
resource "azurerm_storage_account" "eu_storage" {
  name                     = var.eu_storage_account_name
  resource_group_name      = azurerm_resource_group.eu.name
  location                 = azurerm_resource_group.eu.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_share" "eu_file_share" {
  name                 = var.eu_file_share_name
  storage_account_name = azurerm_storage_account.eu_storage.name
  quota                = 10 # Quota in GB
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.eu.location
  resource_group_name = azurerm_resource_group.eu.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # Adjust as per your requirements
}

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "diag_setting" {
  name                       = "storageaccount-log-analytics"
  target_resource_id         = azurerm_storage_account.eu_storage.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  # Storage account logs
  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}


# Output file share URL
output "file_share_url" {
  value = azurerm_storage_account.eu_storage.primary_file_endpoint
}

# Output Log Analytics Workspace ID
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics.id
}