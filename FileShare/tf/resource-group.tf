# EU Resource Group
resource "azurerm_resource_group" "eu" {
  name     = "${var.name_prefix}${var.eu_resource_group_name}"
  location = var.eu_resource_location
}

# USA Resource Group
resource "azurerm_resource_group" "us" {
  name     = "${var.name_prefix}${var.us_resource_group_name}"
  location = var.us_resource_location
}