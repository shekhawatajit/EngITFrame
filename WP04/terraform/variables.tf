variable "location" {
  description = "The location/region where the Azure resources are created."
  type        = string
  default     = "Germany West Central"
}

variable "vnet_rg_name" {
  description = "The name of resource group where the virtual network will be created."
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "The address space that is used the virtual network."
  type        = string
}

variable "vnet_subnet_address_prefix" {
  description = "The address prefix of the subnet"
  type        = string
}

variable "nsg_name" {
  description = "The name of the network security group. Changing this forces a new resource to be created."
  type        = string
}

variable "observability_server_rg_name" {
  description = "The name of resource group where the monitoring server VM will be created."
  type        = string
}

variable "observability_server_name" {
  description = "The name of the virtual machine hosting the monitoring stack."
  type        = string
}

variable "observability_server_ip_address" {
  description = "The private IP address of the virtual machine hosting the monitoring stack."
  type        = string
}

variable "workload_vm_rg_name" {
  description = "The name of the resource group where the workload VMs will be created."
  type        = string
}

variable "workload_vm_key_vault_name" {
  description = "The name of the Key Vault."
  type        = string
}

variable "workload_vm_linux_prefix" {
  description = "The name prefix of the Linux workload VMs."
  type        = string
}

variable "workload_vm_linux_ip_addresses" {
  description = "The private IP addresses of the Linux workload VMs."
  type        = list(string)
}

variable "workload_vm_windows_prefix" {
  description = "The name prefix of the Windows workload VMs."
  type        = string
}

variable "workload_vm_windows_ip_addresses" {
  description = "The private IP addresses of the Windows workload VMs."
  type        = list(string)
}
