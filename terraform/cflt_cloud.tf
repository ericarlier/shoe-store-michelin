data "confluent_organization" "workshop_org" {}
# -------------------------------------------------------
# Retrieve Users
# -------------------------------------------------------
data "confluent_user" "workshop_user" {
  for_each = tomap(var.workshop_users)
  email = "${each.value}"
}

# -------------------------------------------------------
# Confluent Cloud Environment
# -------------------------------------------------------
resource "confluent_environment" "cc_handson_env" {
  display_name = "${var.use_prefix}${var.cc_env_name}"
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Schema Registry
# --------------------------------------------------------
data "confluent_schema_registry_region" "cc_handson_sr" {
  cloud   = var.sr_cloud_provider
  region  = var.sr_cloud_region
  package = var.sr_package
}

resource "confluent_schema_registry_cluster" "cc_sr_cluster" {
  package = data.confluent_schema_registry_region.cc_handson_sr.package
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  region {
    id = data.confluent_schema_registry_region.cc_handson_sr.id
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Confluent Cloud Kafka Cluster
# --------------------------------------------------------
resource "confluent_kafka_cluster" "cc_kafka_cluster" {
  display_name = "${var.use_prefix}${var.cc_cluster_name}"
  availability = var.cc_availability
  cloud        = var.cc_cloud_provider
  region       = var.cc_cloud_region
  standard {}
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Flink Compute Pool
# --------------------------------------------------------
resource "confluent_flink_compute_pool" "cc_flink_compute_pool" {
  for_each = tomap(var.workshop_users)
  display_name = "${each.key}_${var.cc_dislay_name}"
  cloud        = var.cc_cloud_provider
  region       = var.cc_cloud_region
  max_cfu      = var.cc_compute_pool_cfu
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  depends_on = [
    confluent_kafka_cluster.cc_kafka_cluster
  ]
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Assign restricted roles to user
# --------------------------------------------------------
resource "confluent_role_binding" "flinkdev-role-binding" {
  for_each = tomap(var.workshop_users)
  principal   = "User:${data.confluent_user.workshop_user[each.key].id}"
  role_name   = "FlinkDeveloper"
  crn_pattern = confluent_environment.cc_handson_env.resource_name
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "discovery-role-binding" {
  for_each = tomap(var.workshop_users)
  principal   = "User:${data.confluent_user.workshop_user[each.key].id}"
  role_name   = "DataDiscovery"
  crn_pattern = confluent_environment.cc_handson_env.resource_name
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "allow_shoe_read" {
  for_each = tomap(var.workshop_users)
  principal   = "User:${data.confluent_user.workshop_user[each.key].id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.cc_kafka_cluster.rbac_crn}/kafka=${confluent_kafka_cluster.cc_kafka_cluster.id}/topic=shoe_*"
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "allow_shoe_read_subjects" {
  for_each = tomap(var.workshop_users)
  principal   = "User:${data.confluent_user.workshop_user[each.key].id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_schema_registry_cluster.cc_sr_cluster.resource_name}/subject=shoe_*"
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "team_tenant_owner" {
  for_each = tomap(var.workshop_users)
  principal   = "User:${data.confluent_user.workshop_user[each.key].id}"
  role_name   = "ResourceOwner"
  crn_pattern = "${confluent_kafka_cluster.cc_kafka_cluster.rbac_crn}/kafka=${confluent_kafka_cluster.cc_kafka_cluster.id}/topic=${each.key}_*"
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "team_tenant_owner_subjects" {
  for_each = tomap(var.workshop_users)
  principal   = "User:${data.confluent_user.workshop_user[each.key].id}"
  role_name   = "ResourceOwner"
  crn_pattern = "${confluent_schema_registry_cluster.cc_sr_cluster.resource_name}/subject=${each.key}_*"
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "transaction-id-rb" {
  for_each = tomap(var.workshop_users)
  principal   = "User:${data.confluent_user.workshop_user[each.key].id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.cc_kafka_cluster.rbac_crn}/kafka=${confluent_kafka_cluster.cc_kafka_cluster.id}/transactional-id=*"
}

# --------------------------------------------------------
# Service Accounts (app_manager, sr, clients)
# --------------------------------------------------------
resource "confluent_service_account" "app_manager" {
  display_name = "${var.use_prefix}-app-manager"
  description  = local.description
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Role Bindings (app_manager, sr, clients)
# --------------------------------------------------------
resource "confluent_role_binding" "app_manager_environment_admin" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.cc_handson_env.resource_name
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "app_manager_data_steward" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "DataSteward"
  crn_pattern = confluent_environment.cc_handson_env.resource_name
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Credentials / API Keys
# --------------------------------------------------------
# app_manager
resource "confluent_api_key" "app_manager_kafka_cluster_key" {
  display_name = "app-manager-${var.cc_cluster_name}-key"
  description  = local.description
  owner {
    id          = confluent_service_account.app_manager.id
    api_version = confluent_service_account.app_manager.api_version
    kind        = confluent_service_account.app_manager.kind
  }
  managed_resource {
    id          = confluent_kafka_cluster.cc_kafka_cluster.id
    api_version = confluent_kafka_cluster.cc_kafka_cluster.api_version
    kind        = confluent_kafka_cluster.cc_kafka_cluster.kind
    environment {
      id = confluent_environment.cc_handson_env.id
    }
  }
  depends_on = [
    confluent_role_binding.app_manager_environment_admin
  ]
  lifecycle {
    prevent_destroy = false
  }
}
# Schema Registry
resource "confluent_api_key" "sr_cluster_key" {
  display_name = "appmanger-sr-${var.cc_cluster_name}-key"
  description  = local.description
  owner {
    id          = confluent_service_account.app_manager.id
    api_version = confluent_service_account.app_manager.api_version
    kind        = confluent_service_account.app_manager.kind
  }
  managed_resource {
    id          = confluent_schema_registry_cluster.cc_sr_cluster.id
    api_version = confluent_schema_registry_cluster.cc_sr_cluster.api_version
    kind        = confluent_schema_registry_cluster.cc_sr_cluster.kind
    environment {
      id = confluent_environment.cc_handson_env.id
    }
  }
  depends_on = [
    confluent_role_binding.app_manager_data_steward
  ]
  lifecycle {
    prevent_destroy = false
  }
}

