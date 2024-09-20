provider "azurerm" {
  subscription_id = var.az_subscription_id
  features {}
}

# EU Resources
# Resource Groups
resource "azurerm_resource_group" "eu" {
  name     = "${var.name_prefix}${var.eu_resource_group_name}"
  location = var.eu_resource_location
}
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

# Create a Private DNS Zone for the Storage Account
resource "azurerm_private_dns_zone" "storage_account_dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.eu.name
}


# Link the Private DNS Zone to the Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "${var.name_prefix}vnet_link"
  resource_group_name   = azurerm_resource_group.eu.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.eu_vnet.id
}

# Create DNS A Record for the Private Endpoint
resource "azurerm_private_dns_a_record" "file_share_a_record" {
  name                = azurerm_storage_account.eu_storage.name
  zone_name           = azurerm_private_dns_zone.storage_account_dns_zone.name
  resource_group_name = azurerm_resource_group.eu.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.file_share_private_endpoint.private_service_connection.0.private_ip_address]
}
# Storage Account and File Share
resource "azurerm_storage_account" "eu_storage" {
  name                     = "${var.name_prefix}${var.eu_storage_account_name}"
  resource_group_name      = azurerm_resource_group.eu.name
  location                 = azurerm_resource_group.eu.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  default_to_oauth_authentication = true
  identity {
    type = "SystemAssigned"
  }
  #   azure_files_authentication {
  #   directory_type = "AADDS"
  # }
}

resource "azurerm_storage_share" "eu_file_share" {
  name                 = "${var.name_prefix}${var.eu_file_share_name}"
  storage_account_name = azurerm_storage_account.eu_storage.name
  enabled_protocol     = "SMB"
  quota                = 10 # Quota in GB
  acl {
    id = var.fileshare_principal_id # Replace with Azure AD Object ID
    access_policy {
       permissions = "rwdl"
    }
  }
}
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "${var.name_prefix}${var.log_analytics_workspace_name}"
  location            = azurerm_resource_group.eu.location
  resource_group_name = azurerm_resource_group.eu.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # Adjust as per your requirements
}

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "diag_setting" {
  name                       = "${var.name_prefix}${var.azurerm_monitor_diagnostic_setting_name}"
  target_resource_id         = "${azurerm_storage_account.eu_storage.id}/fileServices/default/"
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
# Assign Azure AD role to users for accessing the File Share
resource "azurerm_role_assignment" "fileshare_role" {
  principal_id         = var.fileshare_principal_id    # Replace with Azure AD Object ID
  role_definition_name = "Storage File Data SMB Share Contributor"
  scope                = azurerm_storage_account.eu_storage.id
}



# US Resource
# Resource Groups
resource "azurerm_resource_group" "us" {
  name     = "${var.name_prefix}${var.us_resource_group_name}"
  location = var.us_resource_location
}

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

# Link the Private DNS Zone to the US Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "us_vnet_link" {
  name                  = "${var.name_prefix}us_vnet_link"
  resource_group_name   = azurerm_resource_group.eu.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.us_vnet.id
}


resource "azurerm_virtual_machine" "us_vm" {
  name                  = "${var.name_prefix}-us-vm"
  location              = azurerm_resource_group.us.location
  resource_group_name   = azurerm_resource_group.us.name
  network_interface_ids = [azurerm_network_interface.us_vm_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.name_prefix}-us-vm"
    admin_username = var.vm_username 
    admin_password = var.vm_password
  }
  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
  identity {
    type = "SystemAssigned"
  }
}
# Install the AADLoginForWindows extension
resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_virtual_machine.us_vm.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}


# Output file share URL
output "file_share_url" {
  value = azurerm_storage_account.eu_storage.primary_file_endpoint
}

# Output Log Analytics Workspace ID
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics.id
}