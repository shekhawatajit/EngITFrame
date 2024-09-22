terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateengitcg"
    container_name       = "wp01"
    key                  = "wp01.tfstate"
  }
}
