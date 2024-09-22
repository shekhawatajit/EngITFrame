# Output file share URL
output "file_share_url" {
  value = azurerm_storage_account.eu_storage.primary_file_endpoint
}

# Output Log Analytics Workspace ID
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics.id
}