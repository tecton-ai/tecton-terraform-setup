terraform {
  required_version = ">= 0.13"
  required_providers {
    rediscloud = {
      source  = "redisLabs/rediscloud"
      version = "~> 1.1.1"
    }
  }
}

provider "rediscloud" {
  api_key    = var.api_key
  secret_key = var.secret_key
}

resource "rediscloud_subscription" "subscription-resource" {
  name           = "${var.cluster_name}-${var.region}-subscription"
  payment_method = "marketplace"

  cloud_provider {
    # Running in GCP on Redis resources
    provider = "GCP"
    region {
      region                       = var.region
      networking_deployment_cidr   = var.deployment_cidr
      preferred_availability_zones = var.zones
      multiple_availability_zones  = true
    }
  }
  creation_plan {
    memory_limit_in_gb           = 1
    quantity                     = 1
    replication                  = true
    support_oss_cluster_api      = true
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = 10000
    modules                      = []
  }
}

resource "rediscloud_subscription_database" "database-resource" {
  subscription_id                       = rediscloud_subscription.subscription-resource.id
  name                                  = "${var.cluster_name}-${var.region}-redis"
  protocol                              = "redis"
  memory_limit_in_gb                    = 10
  data_persistence                      = "snapshot-every-12-hours"
  throughput_measurement_by             = "operations-per-second"
  throughput_measurement_value          = 10000
  support_oss_cluster_api               = true
  external_endpoint_for_oss_cluster_api = true
  replication                           = true
  enable_tls                            = true
  data_eviction                         = "noeviction"

  alert {
    name  = "dataset-size"
    value = 80
  }

  alert {
    name  = "throughput-higher-than"
    value = 9000
  }

  depends_on = [rediscloud_subscription.subscription-resource]

}

resource "rediscloud_subscription_peering" "databricks-peering" {
  subscription_id  = rediscloud_subscription.subscription-resource.id
  provider_name    = "GCP"
  gcp_project_id   = var.databricks_peering_project
  gcp_network_name = var.databricks_vpc_network_name
}

resource "rediscloud_subscription_peering" "serving-peering" {
  subscription_id  = rediscloud_subscription.subscription-resource.id
  provider_name    = "GCP"
  gcp_project_id   = var.serving_peering_project
  gcp_network_name = var.serving_vpc_network_name
}
