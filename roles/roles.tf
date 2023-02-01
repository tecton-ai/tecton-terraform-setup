locals {
  tags                                = { "tecton-accessible:${var.deployment_name}" : "true" }
  fargate_kinesis_delivery_stream_arn = "arn:aws:firehose:${var.region}:${var.account_id}:deliverystream/tecton-${var.deployment_name}-fargate-log-delivery-stream"
}

# EKS [Common : Databricks and EMR]
data "template_file" "eks_policy_json" {
  template = file("${path.module}/../templates/eks_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# EKS [Common : Databricks and EMR]
data "template_file" "devops_policy_json_1" {
  template = file("${path.module}/../templates/devops_policy_1.json")
  vars = {
    ACCOUNT_ID             = var.account_id
    DEPLOYMENT_NAME        = var.deployment_name
    DEPLOYMENT_NAME_CONCAT = format("%.24s", "tecton-${var.deployment_name}")
    REGION                 = var.region
  }
}

# EKS [Common : Databricks and EMR]
data "template_file" "devops_policy_json_2" {
  template = file("${path.module}/../templates/devops_policy_2.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# EKS [Common : Databricks and EMR]
data "template_file" "devops_ingest_policy_json" {
  count = var.enable_ingest_api ? 1 : 0

  template = file("${path.module}/../templates/devops_ingest_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# Fargate [Common : Databricks and EMR]
data "template_file" "eks_fargate_node" {
  count = var.fargate_enabled ? 1 : 0

  template = file("${path.module}/../templates/fargate_eks_role.json")
  vars = {
    ACCOUNT_ID          = var.account_id
    ASSUMING_ACCOUNT_ID = var.tecton_assuming_account_id
    DEPLOYMENT_NAME     = var.deployment_name
    REGION              = var.region
  }
}

# Fargate [Common : Databricks and EMR]
resource "aws_iam_policy" "eks_fargate_node_policy" {
  count = var.fargate_enabled ? 1 : 0

  name   = "tecton-${var.deployment_name}-eks-fargate-node-policy"
  policy = data.template_file.eks_fargate_node[0].rendered
  tags   = local.tags
}

# Fargate [Common : Databricks and EMR]
data "template_file" "devops_fargate_role_json" {
  count    = var.fargate_enabled ? 1 : 0
  template = file("${path.module}/../templates/devops_fargate.json")
  vars = {
    ACCOUNT_ID         = var.account_id
    DEPLOYMENT_NAME    = var.deployment_name
    REGION             = var.region
    FARGATE_POLICY_ARN = aws_iam_policy.eks_fargate_node_policy[0].arn
  }
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_policy" "devops_fargate_policy" {
  count = var.fargate_enabled ? 1 : 0

  name   = "tecton-${var.deployment_name}-devops-fargate-policy"
  policy = data.template_file.devops_fargate_role_json[0].rendered
  tags   = local.tags
}

# EKS [Common : Databricks and EMR]
data "template_file" "devops_eks_policy_json" {
  template = file("${path.module}/../templates/devops_eks_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# EKS [Common : Databricks and EMR]
data "template_file" "devops_eks_vpc_endpoint_policy_json" {
  count = var.enable_eks_ingress_vpc_endpoint ? 1 : 0

  template = file("${path.module}/../templates/devops_eks_vpc_endpoint_policy.json")
  vars = {
    DEPLOYMENT_NAME = var.deployment_name
  }
}

# Elasticache [Common : Databricks and EMR]
data "template_file" "devops_elasticache_policy_json" {
  template = file("${path.module}/../templates/devops_elasticache_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

data "template_file" "assume_role_policy" {
  template = file("${path.module}/../templates/assume_role.json")
  vars = {
    ASSUMING_ACCOUNT_ID = var.tecton_assuming_account_id
  }
}

data "template_file" "assume_role_external_id_policy" {
  template = file("${path.module}/../templates/assume_role_external_id.json")
  vars = {
    ASSUMING_ACCOUNT_ID = var.tecton_assuming_account_id
    EXTERNAL_ID         = var.external_id
  }
}

# Spark : Databricks
data "template_file" "spark_policy_json" {
  count    = var.create_emr_roles ? 0 : 1
  template = file("${path.module}/../templates/spark_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# Spark : Databricks
data "template_file" "cross_account_databricks_json" {
  count    = var.create_emr_roles ? 0 : 1
  template = file("${path.module}/../templates/cross_account_databricks.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# Spark Policy : EMR
data "template_file" "emr_spark_policy_json" {
  count    = var.create_emr_roles ? 1 : 0
  template = file("${path.module}/../templates/emr_spark_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# Spark Master Policy : EMR
data "template_file" "emr_master_policy_json" {
  count    = var.create_emr_roles ? 1 : 0
  template = file("${path.module}/../templates/emr_master_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
    SPARK_ROLE      = aws_iam_role.emr_spark_role[0].name
  }
}

# Spark Cross Account Policy : EMR
data "template_file" "emr_access_policy_json" {
  count    = var.create_emr_roles ? 1 : 0
  template = file("${path.module}/../templates/emr_ca_policy.json")
  vars = {
    ACCOUNT_ID       = var.account_id
    DEPLOYMENT_NAME  = var.deployment_name
    REGION           = var.region
    EMR_MANAGER_ROLE = aws_iam_role.emr_master_role[0].name
    SPARK_ROLE       = aws_iam_role.emr_spark_role[0].name
  }
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role" "devops_role" {
  name               = "tecton-${var.deployment_name}-devops-role"
  tags               = local.tags
  assume_role_policy = var.external_id != "" ? data.template_file.assume_role_external_id_policy.rendered : data.template_file.assume_role_policy.rendered
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_policy" "devops_policy_1" {
  name   = "tecton-${var.deployment_name}-devops-policy-1"
  policy = data.template_file.devops_policy_json_1.rendered
  tags   = local.tags
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_policy" "devops_policy_2" {
  name   = "tecton-${var.deployment_name}-devops-policy-2"
  policy = data.template_file.devops_policy_json_2.rendered
  tags   = local.tags
}

resource "aws_iam_policy" "devops_ingest_policy" {
  count = var.enable_ingest_api ? 1 : 0

  name   = "tecton-${var.deployment_name}-devops-ingest-policy"
  policy = data.template_file.devops_ingest_policy_json[0].rendered
  tags   = local.tags
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_policy" "devops_eks_policy" {
  name   = "tecton-${var.deployment_name}-devops-eks-policy"
  policy = data.template_file.devops_eks_policy_json.rendered
  tags   = local.tags
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_policy" "devops_eks_vpc_endpoint_policy" {
  count = var.enable_eks_ingress_vpc_endpoint ? 1 : 0

  name   = "tecton-${var.deployment_name}-devops-eks-vpce"
  policy = data.template_file.devops_eks_vpc_endpoint_policy_json[0].rendered
  tags   = local.tags
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_policy" "devops_elasticache_policy" {
  count  = var.elasticache_enabled ? 1 : 0
  name   = "tecton-${var.deployment_name}-devops-elasticache-policy"
  policy = data.template_file.devops_elasticache_policy_json.rendered
  tags   = local.tags
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "devops_policy_attachment_1" {
  policy_arn = aws_iam_policy.devops_policy_1.arn
  role       = aws_iam_role.devops_role.name
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "devops_policy_attachment_2" {
  policy_arn = aws_iam_policy.devops_policy_2.arn
  role       = aws_iam_role.devops_role.name
}

resource "aws_iam_role_policy_attachment" "devops_ingest_policy_attachment" {
  count = var.enable_ingest_api ? 1 : 0

  policy_arn = aws_iam_policy.devops_ingest_policy[0].arn
  role       = aws_iam_role.devops_role.name
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "devops_fargate_policy_attachment" {
  count = var.fargate_enabled ? 1 : 0

  policy_arn = aws_iam_policy.devops_fargate_policy[0].arn
  role       = aws_iam_role.devops_role.name
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "devops_eks_policy_attachment" {
  policy_arn = aws_iam_policy.devops_eks_policy.arn
  role       = aws_iam_role.devops_role.name
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "devops_eks_vpc_endpoint_policy_attachment" {
  count = var.enable_eks_ingress_vpc_endpoint ? 1 : 0

  policy_arn = aws_iam_policy.devops_eks_vpc_endpoint_policy[0].arn
  role       = aws_iam_role.devops_role.name
}

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "devops_elasticache_policy_attachment" {
  count      = var.elasticache_enabled ? 1 : 0
  policy_arn = aws_iam_policy.devops_elasticache_policy[0].arn
  role       = aws_iam_role.devops_role.name
}

# EKS MANAGEMENT [Common : Databricks and EMR]
resource "aws_iam_role" "eks_management_role" {
  name               = "tecton-${var.deployment_name}-eks-management-role"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# EKS MANAGEMENT [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "eks_management_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ])
  policy_arn = each.value
  role       = aws_iam_role.eks_management_role.name
}

# EKS VPC Management [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "tecton-eks-cluster-AmazonEKSVPCResourceController" {
  count      = var.fargate_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_management_role.name
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_role" "eks_node_role" {
  name               = "tecton-${var.deployment_name}-eks-worker-role"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_policy" "eks_node_policy" {
  name   = "tecton-${var.deployment_name}-eks-worker-policy"
  policy = data.template_file.eks_policy_json.rendered
  tags   = local.tags
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  policy_arn = aws_iam_policy.eks_node_policy.arn
  role       = aws_iam_role.eks_node_role.name
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ])
  policy_arn = each.value
  role       = aws_iam_role.eks_node_role.name
}

# Spark Access Policy : EMR only
resource "aws_iam_policy" "emr_access_policy" {
  count  = var.create_emr_roles ? 1 : 0
  name   = "tecton-${var.deployment_name}-spark-access-policy-emr"
  policy = data.template_file.emr_access_policy_json[0].rendered
  tags   = local.tags
}

# EKS NODE : EMR Only attachment
resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment_emr" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.emr_access_policy[0].arn
  role       = aws_iam_role.eks_node_role.name
}

provider "aws" {
  alias = "databricks-account"
}

# Spark Common : Databricks and EMR
resource "aws_iam_policy" "common_spark_policy" {
  provider = aws.databricks-account
  name     = "tecton-${var.deployment_name}-common-spark-policy"
  policy   = var.create_emr_roles ? data.template_file.emr_spark_policy_json[0].rendered : data.template_file.spark_policy_json[0].rendered
  tags     = local.tags
}

# Spark Common : Databricks and EMR
resource "aws_iam_role_policy_attachment" "common_spark_policy_attachment" {
  provider   = aws.databricks-account
  policy_arn = aws_iam_policy.common_spark_policy.arn
  role       = var.create_emr_roles ? (var.emr_spark_role_name != null ? var.emr_spark_role_name : "tecton-${var.deployment_name}-emr-spark-role") : var.spark_role_name
}

resource "aws_iam_policy" "satellite_region_policy" {
  count = var.satellite_region != null ? 1 : 0
  name  = "tecton-satellite-region-policy"
  policy = file("${path.module}/../templates/satellite_ca_policy.json", {
    ACCOUNT_ID       = var.account_id
    DEPLOYMENT_NAME  = var.deployment_name
    REGION           = var.region
    SATELLITE_REGION = var.satellite_region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "satellite_region_policy_attachment" {
  count      = var.satellite_region != null ? 1 : 0
  policy_arn = aws_iam_policy.satellite_region_policy[0].arn
  role       = var.create_emr_roles ? (var.emr_spark_role_name != null ? var.emr_spark_role_name : "tecton-${var.deployment_name}-emr-spark-role") : var.spark_role_name
}

# Ingest API - Common for Databricks and EMR.

## IAM Policy Document - Allow Cloudwatch Logging
# Allow Lambda to assume this role for the online ingest lambda.
data "aws_iam_policy_document" "ingest_api_assume_policy" {
  count = var.enable_ingest_api ? 1 : 0

  statement {
    sid     = "LambdaRoleAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Online Ingest
resource "aws_iam_role" "online_ingest_role" {
  count = var.enable_ingest_api ? 1 : 0

  name               = "tecton-${var.deployment_name}-online-ingest"
  assume_role_policy = data.aws_iam_policy_document.ingest_api_assume_policy[0].json
  tags               = local.tags
}

# This file contains the permissions needed by the Ingest API Writer to write to Dynamo, Kinesis (for offline logging)
# and SQS in case of DLQ.
data "template_file" "online_ingest_role_json" {
  count    = var.enable_ingest_api ? 1 : 0
  template = file("${path.module}/../templates/online_ingest_role.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

resource "aws_iam_policy" "online_ingest_role_policy" {
  count = var.enable_ingest_api ? 1 : 0

  name   = "tecton-${var.deployment_name}-online-ingest"
  policy = data.template_file.online_ingest_role_json[0].rendered
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "online_ingest_attachment" {
  count = var.enable_ingest_api ? 1 : 0

  policy_arn = aws_iam_policy.online_ingest_role_policy[0].arn
  role       = aws_iam_role.online_ingest_role[0].name
}

# Needed for Lambda to talk to Redis
# From AWS Docs : Provides minimum permissions for a Lambda function to execute while accessing a resource within a
# VPC - create, describe, delete network interfaces and write permissions to CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "online_lambda_role_vpc" {
  count = var.enable_ingest_api ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.online_ingest_role[0].name
}


// Offline Ingest
resource "aws_iam_role" "offline_ingest_role" {
  count = var.enable_ingest_api ? 1 : 0

  name               = "tecton-${var.deployment_name}-offline-ingest"
  assume_role_policy = data.aws_iam_policy_document.ingest_api_assume_policy[0].json
  tags               = local.tags
}

// This file contains the permissions needed by the Ingest API Writer to write to Dynamo, Kinesis (for offline logging)
// and SQS in case of DLQ.
data "template_file" "offline_ingest_role_json" {
  count    = var.enable_ingest_api ? 1 : 0
  template = file("${path.module}/../templates/offline_ingest_role.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

resource "aws_iam_policy" "offline_ingest_role_policy" {
  count = var.enable_ingest_api ? 1 : 0

  name   = "tecton-${var.deployment_name}-offline-ingest"
  policy = data.template_file.offline_ingest_role_json[0].rendered
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "offline_ingest_attachment" {
  count = var.enable_ingest_api ? 1 : 0

  policy_arn = aws_iam_policy.offline_ingest_role_policy[0].arn
  role       = aws_iam_role.offline_ingest_role[0].name
}

# Needed for Lambda to talk to Redis
# From AWS Docs : Provides minimum permissions for a Lambda function to execute while accessing a resource within a
# VPC - create, describe, delete network interfaces and write permissions to CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "offline_lambda_role_vpc" {
  count = var.enable_ingest_api ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.offline_ingest_role[0].name
}


# Ingest API Management Permissions
# This file contains the permissions needed by the control plane services to deploy new versions of the Ingest API,
# update ALB accordingly, and also to discover the offline log on the fly.
data "template_file" "online_ingest_management_policy_json" {
  count = var.enable_ingest_api ? 1 : 0

  template = file("${path.module}/../templates/online_ingest_management_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

resource "aws_iam_policy" "online_ingest_management_policy" {
  count = var.enable_ingest_api ? 1 : 0

  name   = "tecton-${var.deployment_name}-ingest-manage"
  policy = data.template_file.online_ingest_management_policy_json[0].rendered
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "online_ingest_management_policy_attachment" {
  count = var.enable_ingest_api ? 1 : 0

  policy_arn = aws_iam_policy.online_ingest_management_policy[0].arn
  role       = aws_iam_role.eks_node_role.id
}

# CROSS-ACCOUNT ACCESS FOR SPARK : Databricks
resource "aws_iam_role" "spark_cross_account_role" {
  count                = var.create_emr_roles ? 0 : 1
  name                 = "tecton-${var.deployment_name}-cross-account-spark-access"
  max_session_duration = 43200
  tags                 = local.tags
  assume_role_policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.databricks_account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# CROSS-ACCOUNT ACCESS FOR SPARK : Databricks
resource "aws_iam_policy" "cross_account_databricks_policy" {
  count  = var.create_emr_roles ? 0 : 1
  name   = "tecton-${var.deployment_name}-cross-account-databricks-policy"
  policy = data.template_file.cross_account_databricks_json[0].rendered
  tags   = local.tags
}

# CROSS-ACCOUNT ACCESS FOR SPARK : Databricks
resource "aws_iam_role_policy_attachment" "cross_account_databricks_policy_attachment" {
  count      = var.create_emr_roles ? 0 : 1
  policy_arn = aws_iam_policy.cross_account_databricks_policy[0].arn
  role       = aws_iam_role.spark_cross_account_role[0].name
}

# SPARK ROLE : EMR
resource "aws_iam_role" "emr_spark_role" {
  count              = var.create_emr_roles ? 1 : 0
  name               = var.emr_spark_role_name != null ? var.emr_spark_role_name : "tecton-${var.deployment_name}-emr-spark-role"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# SPARK ROLE POLICY : EMR
resource "aws_iam_policy" "emr_spark_policy" {
  count  = var.create_emr_roles ? 1 : 0
  name   = "tecton-${var.deployment_name}-spark-policy-emr"
  policy = data.template_file.emr_spark_policy_json[0].rendered
  tags   = local.tags
}

# SPARK ROLE POLICY ATTACHMENT: EMR
resource "aws_iam_role_policy_attachment" "emr_spark_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.emr_spark_policy[0].arn
  role       = aws_iam_role.emr_spark_role[0].name
}

# CROSS-ACCOUNT ACCESS FOR SATELLITE SERVING
resource "aws_iam_policy" "cross_account_satellite_region_policy" {
  count = var.satellite_region != null ? 1 : 0
  name  = "tecton-${var.deployment_name}-cross-account-satellite-region-policy-emr"
  policy = file("${path.module}/../templates/satellite_serving_dynamodb_policy.json")
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "emr_cross_account_satellite_region_policy_attachment" {
  count      = var.satellite_region != null ? 1 : 0
  policy_arn = aws_iam_policy.emr_cross_account_satellite_region_policy[0].arn
  role       = var.create_emr_roles ? aws_iam_role.emr_spark_role[0].name : aws_iam_role.spark_cross_account_role[0].name
}

# SPARK ROLE SSM POLICY ATTACHMENT: EMR
resource "aws_iam_role_policy_attachment" "emr_ssm_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.emr_spark_role[0].name
}

# SPARK INSTANCE PROFILE : EMR
resource "aws_iam_instance_profile" "emr_spark_instance_profile" {
  count = var.create_emr_roles ? 1 : 0
  name  = "tecton-${var.deployment_name}-emr-spark-role"
  role  = aws_iam_role.emr_spark_role[0].name
}

# SPARK MASTER NODE ROLE : EMR
resource "aws_iam_role" "emr_master_role" {
  count              = var.create_emr_roles ? 1 : 0
  name               = "tecton-${var.deployment_name}-emr-master-role"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# SPARK MASTER POLICY : EMR
resource "aws_iam_policy" "emr_master_policy" {
  count  = var.create_emr_roles ? 1 : 0
  name   = "tecton-${var.deployment_name}-master-policy-emr"
  policy = data.template_file.emr_master_policy_json[0].rendered
  tags   = local.tags
}

# SPARK MASTER POLICY ATTACHMENT : EMR
resource "aws_iam_role_policy_attachment" "emr_master_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.emr_master_policy[0].arn
  role       = aws_iam_role.emr_master_role[0].name
}

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

resource "aws_iam_service_linked_role" "eks-nodegroup" {
  aws_service_name = "eks-nodegroup.amazonaws.com"
}

resource "aws_iam_service_linked_role" "eks-fargate" {
  aws_service_name = "eks-fargate.amazonaws.com"
}

# FARGATE [Common : Databricks and EMR]
data "aws_iam_policy_document" "kinesis_firehose_stream" {
  count   = var.fargate_enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["firehose.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
  }
}

# Resources to enable logs output to S3
resource "aws_iam_role" "kinesis_firehose_stream" {
  count              = var.fargate_enabled ? 1 : 0
  name               = "tecton-${var.deployment_name}-fargate-kinesis-firehose"
  assume_role_policy = data.aws_iam_policy_document.kinesis_firehose_stream[0].json
}

data "aws_iam_policy_document" "fargate_logging_cross_account_write" {
  count   = var.fargate_enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::tecton-logs-aggregation/${var.deployment_name}",
      "arn:aws:s3:::tecton-logs-aggregation/${var.deployment_name}/*"
    ]
  }
}

resource "aws_iam_policy" "fargate_logging_cross_account" {
  count  = var.fargate_enabled ? 1 : 0
  name   = "tecton-${var.deployment_name}-fargate-cross-account-write"
  policy = data.aws_iam_policy_document.fargate_logging_cross_account_write[0].json
}

resource "aws_iam_role_policy_attachment" "logging_write" {
  count      = var.fargate_enabled ? 1 : 0
  role       = aws_iam_role.kinesis_firehose_stream[0].name
  policy_arn = aws_iam_policy.fargate_logging_cross_account[0].arn
}

# Resources for EKS fargate pod execution role
data "aws_iam_policy_document" "eks_fargate_assume_role" {
  count   = var.fargate_enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = ["eks-fargate-pods.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "eks_fargate_pod_execution" {
  count              = var.fargate_enabled ? 1 : 0
  name               = "tecton-${var.deployment_name}-eks-fargate-pod-execution"
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_assume_role[0].json
}

data "aws_iam_policy_document" "fargate_logging_policy" {
  count   = var.fargate_enabled ? 1 : 0
  version = "2012-10-17"
  statement {
    actions = [
      "firehose:PutRecordBatch",
    ]
    effect = "Allow"
    resources = [
      local.fargate_kinesis_delivery_stream_arn
    ]
  }
}

resource "aws_iam_policy" "fargate_logging" {
  count  = var.fargate_enabled ? 1 : 0
  name   = "tecton-${var.deployment_name}-fargate-logging-to-kinesis-firehose"
  policy = data.aws_iam_policy_document.fargate_logging_policy[0].json
}

resource "aws_iam_role_policy_attachment" "logging" {
  count      = var.fargate_enabled ? 1 : 0
  role       = aws_iam_role.eks_fargate_pod_execution[0].name
  policy_arn = aws_iam_policy.fargate_logging[0].arn
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  count      = var.fargate_enabled ? 1 : 0
  role       = aws_iam_role.eks_fargate_pod_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}
