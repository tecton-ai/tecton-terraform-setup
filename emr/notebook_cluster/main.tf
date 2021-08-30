locals {
  tags = { "tecton-accessible:${var.deployment_name}" : "true" }

  hive_config = [
    {
      Classification : "hive-site",
      Properties : {
        "hive.metastore.client.factory.class" : "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory",
        "hive.metastore.glue.catalogid" : var.glue_account_id
      }
    },
    {
      Classification : "spark-defaults",
      Properties : {
        "hive.metastore.client.factory.class" : "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory",
        "hive.metastore.glue.catalogid" : var.glue_account_id
      }
    },
    {
      Classification : "spark-hive-site",
      Properties : {
        "hive.metastore.client.factory.class" : "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory",
        "hive.metastore.glue.catalogid" : var.glue_account_id
      }
    }
  ]

  base_config = [
    {
      Classification : "livy-env",
      Properties : {}
      Configurations : [
        {
          Classification : "export",
          Properties : {
            "CLUSTER_REGION" : var.region,
            "TECTON_CLUSTER_NAME" : var.deployment_name
          }
        }
      ]
    },
    {
      Classification : "yarn-env",
      Properties : {},
      Configurations : [
        {
          Classification : "export",
          Properties : {
            "CLUSTER_REGION" : var.region,
          "TECTON_CLUSTER_NAME" : var.deployment_name }
        }
      ]
    }
  ]
}

resource "aws_emr_cluster" "cluster" {
  name          = "tecton-${var.deployment_name}-notebook-cluster"
  release_label = "emr-5.30.0"

  applications = ["Spark", "Livy", "Hive"]

  ec2_attributes {
    subnet_id                         = var.subnet_id
    emr_managed_master_security_group = var.emr_security_group_id
    emr_managed_slave_security_group  = var.emr_security_group_id
    instance_profile                  = var.instance_profile_arn
    service_access_security_group     = var.emr_service_security_group_id
  }

  master_instance_group {
    instance_type = var.instance_type
  }

  core_instance_group {
    instance_type  = var.instance_type
    instance_count = 1

    ebs_config {
      size                 = "40"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  bootstrap_action {
    name = "tecton_emr_setup"
    path = "s3://tecton.ai.public/install_scripts/setup_emr_notebook_cluster.sh"
  }

  service_role = var.emr_service_role_id

  configurations_json = var.has_glue ? jsonencode(concat(local.hive_config, local.base_config)) : jsonencode(local.base_config)

  step {
    action_on_failure = "TERMINATE_CLUSTER"
    name              = "Setup Hadoop Debugging"

    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = ["state-pusher-script"]
    }
  }

  tags = {
    notebook                                   = "true",
    "tecton-accessible:${var.deployment_name}" = "true",
    tecton-owned                               = "true"
  }
}

### AWS Secrets
resource "aws_secretsmanager_secret" "api_service" {
  name = "tecton-${var.deployment_name}/API_SERVICE"
}
resource "aws_secretsmanager_secret_version" "api_service" {
  secret_id     = aws_secretsmanager_secret.api_service.id
  secret_string = "https://https://${var.deployment_name}.tecton.ai/api"
}
resource "aws_secretsmanager_secret" "tecton_api_key" {
  name = "tecton-${var.deployment_name}/TECTON_API_KEY"
}
