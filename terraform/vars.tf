locals {
  description = "Resource created using terraform for Michelin FlinkSQL Workshop"
}

# --------------------------------------------
# Workshop Users
# --------------------------------------------
variable "workshop_users" {
  type    = map(string)
  default = {
    tokyo = "eric.carlier+dp@confluent.io"
    paris = "eric.carlier+paris@confluent.io"
  }
}


# ----------------------------------------
# Generic prefix to use in a common organization
# ----------------------------------------
variable "use_prefix" {
  description = "If a common organization is being used, and default names are not updated, choose a prefix"
  type        = string
  default     = ""
}

# ----------------------------------------
# Confluent Cloud Kafka cluster variables
# ----------------------------------------
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "cc_cloud_provider" {
  type    = string
  default = "AZURE"
}

variable "cc_cloud_region" {
  type    = string
  default = "westeurope"
}

variable "cc_env_name" {
  type    = string
  default = "flink_handson_terraform"
}

variable "cc_cluster_name" {
  type    = string
  default = "cc_handson_cluster"
}

variable "cc_availability" {
  type    = string
  default = "SINGLE_ZONE"
}

# ------------------------------------------
# Confluent Cloud Schema Registry variables
# ------------------------------------------
variable "sr_cloud_provider" {
  type    = string
  default = "AZURE"
}

variable "sr_cloud_region" {
  type    = string
  default = "westeurope"
}

variable "sr_package" {
  type    = string
  default = "ADVANCED"
}

# --------------------------------------------
# Confluent Cloud Flink Compute Pool variables
# --------------------------------------------
variable "cc_dislay_name" {
  type    = string
  default = "standard_compute_pool"
}

variable "cc_compute_pool_name" {
  type    = string
  default = "cc_handson_flink"
}

variable "cc_compute_pool_cfu" {
  type    = number
  default = 5
}

variable "cc_compute_pool_region" {
  type    = string
  default = "azure.westeurope"
}

# --------------------------------------------
# Confluent Cloud Connectors name
# --------------------------------------------
variable "cc_connector_dsoc_products_name" {
  type    = string
  default = "DSoC_products"
}

variable "cc_connector_dsoc_customers_name" {
  type    = string
  default = "DSoC_customers"
}

variable "cc_connector_dsoc_orders_name" {
  type    = string
  default = "DSoC_orders"
}

variable "connectors_status" {
  type    = string
  default = "RUNNING"
}