# Logging (OSM)

resource "azurerm_log_analytics_workspace" "azurerm_log_analytics" {
  name                = "${local.azurerm_log_analytics_name}"
  location            = "${azurerm_resource_group.azurerm_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
  sku                 = "Standard"
  retention_in_days   = 30
}

# Logging (EventHub)

resource "azurerm_eventhub_namespace" "azurerm_eventhub_ns" {
  name                = "${local.azurerm_eventhub_ns_name}"
  location            = "${azurerm_resource_group.azurerm_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
  sku                 = "Standard"
  capacity            = 1

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_eventhub" "azurerm_apim_eventhub" {
  name                = "${local.azurerm_apim_eventhub_name}"
  namespace_name      = "${azurerm_eventhub_namespace.azurerm_eventhub_ns.name}"
  resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"

  # EventHub Partition Count has to be between 2 and 32
  partition_count   = 2
  message_retention = 7
}

resource "azurerm_eventhub_authorization_rule" "azurerm_apim_eventhub_rule" {
  name                = "${var.azurerm_apim_eventhub_rule}"
  namespace_name      = "${azurerm_eventhub_namespace.azurerm_eventhub_ns.name}"
  resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
  eventhub_name       = "${azurerm_eventhub.azurerm_apim_eventhub.name}"
  listen              = true
  send                = true
  manage              = false
}

# Notification Hub for push notifications
# TODO: set up services credentials
resource "null_resource" "azurerm_notification_hub" {
  triggers = {
    azurerm_resource_group_name = "${azurerm_resource_group.azurerm_resource_group.name}"
    provisioner_version         = "1"
  }

  provisioner "local-exec" {
    command = "${join(" ", list(
      "ts-node ${var.notification_hub_provisioner}",
      "--location ${lower(replace(var.location, " ", ""))}",
      "--azurerm_resource_group ${azurerm_resource_group.azurerm_resource_group.name}",
      "--azurerm_notification_hub_sku ${var.azurerm_notification_hub_sku}",
      "--azurerm_notification_hub_ns ${local.azurerm_notification_hub_ns}",
      "--notification_hub_apns_app_id ${var.notification_hub_apns_app_id}",
      "--notification_hub_apns_name ${var.notification_hub_apns_name}",
      "--notification_hub_apns_endpoint ${var.notification_hub_apns_endpoint}",
      "--notification_hub_apns_key ${var.NOTIFICATION_HUB_APNS_KEY}",
      "--notification_hub_apns_key_id ${var.NOTIFICATION_HUB_APNS_KEY_ID}",
      "--notification_hub_gcm_key ${var.NOTIFICATION_HUB_GCM_KEY}",
      "--azurerm_notification_hub ${local.azurerm_notification_hub}"))
    }"
  }
}