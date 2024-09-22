data "azurerm_client_config" "current" {}

module "avm-res-resources-resourcegroup" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"

  name     = var.workload_vm_rg_name
  location = var.location

  enable_telemetry = false
}

module "avm-res-keyvault-vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.1"

  name                = var.workload_vm_key_vault_name
  location            = var.location
  resource_group_name = module.avm-res-resources-resourcegroup.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enable_telemetry = false
  sku_name         = "standard"
  network_acls = {
    default_action = "Allow"
  }
  role_assignments = {
    "admin" = {
      principal_id               = data.azurerm_client_config.current.object_id
      role_definition_id_or_name = "Key Vault Administrator"
    }
  }
}

module "workload_linux" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.16.0"

  count = 3

  location            = var.location
  resource_group_name = module.avm-res-resources-resourcegroup.name
  name                = "${var.workload_vm_linux_prefix}-${count.index}"
  zone                = 1
  network_interfaces = {
    network_interface_1 = {
      name = "${var.workload_vm_linux_prefix}-nic-${count.index}"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${var.workload_vm_linux_prefix}-nic-${count.index}-ipconfig1"
          private_ip_subnet_resource_id = module.avm-res-network-virtualnetwork.subnets["subnet1"].resource_id
          private_ip_address_allocation = "Static"
          private_ip_address            = var.workload_vm_linux_ip_addresses[count.index]
        }
      }
    }
  }

  enable_telemetry                   = false
  disable_password_authentication    = false
  admin_password                     = azurerm_key_vault_secret.workload_vm_admin_pw.value
  generate_admin_password_or_ssh_key = false
  source_image_reference = {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12"
    version   = "latest"
  }
  sku_size = "Standard_B1s"
  os_type  = "Linux"
}

module "workload_windows" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.16.0"

  count = 3

  location            = var.location
  resource_group_name = module.avm-res-resources-resourcegroup.name
  name                = "${var.workload_vm_windows_prefix}-${count.index}"
  zone                = 1
  network_interfaces = {
    network_interface_1 = {
      name = "${var.workload_vm_windows_prefix}-nic-${count.index}"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${var.workload_vm_windows_prefix}-${count.index}-ipconfig1"
          private_ip_subnet_resource_id = module.avm-res-network-virtualnetwork.subnets["subnet1"].resource_id
          private_ip_address_allocation = "Static"
          private_ip_address            = var.workload_vm_windows_ip_addresses[count.index]
          create_public_ip_address      = true
          public_ip_address_name        = "${var.workload_vm_windows_prefix}-publicip${count.index}"
        }
      }
    }
  }

  enable_telemetry                   = false
  disable_password_authentication    = false
  admin_password                     = azurerm_key_vault_secret.workload_vm_admin_pw.value
  generate_admin_password_or_ssh_key = false
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
  sku_size = "Standard_B2s"
  os_type  = "Windows"
}

resource "random_password" "workload_admin_pw" {
  length           = 20
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  override_special = "-_"

  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "workload_vm_admin_pw" {

  name         = "wp04-workload-admin-password"
  content_type = "plain/text"
  value        = random_password.workload_admin_pw.result
  key_vault_id = module.avm-res-keyvault-vault.resource_id
}
