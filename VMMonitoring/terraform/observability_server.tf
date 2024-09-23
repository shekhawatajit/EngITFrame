module "observability_rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"

  name     = var.observability_server_rg_name
  location = var.location

  enable_telemetry = false
}

module "observability_server" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.16.0"

  location            = var.location
  resource_group_name = module.observability_rg.name
  name                = var.observability_server_name
  zone                = 1
  network_interfaces = {
    network_interface_1 = {
      name = "${var.observability_server_name}-nic"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${var.observability_server_name}-nic-ipconfig1"
          private_ip_subnet_resource_id = module.avm-res-network-virtualnetwork.subnets["subnet1"].resource_id
          private_ip_address_allocation = "Static"
          private_ip_address            = var.observability_server_ip_address
          create_public_ip_address      = true
          public_ip_address_name        = "${var.observability_server_name}-publicip1"
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
