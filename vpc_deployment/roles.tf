locals {
  tags            = { "tecton-accessible:${var.deployment_name}" : "true" }
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
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
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
data "template_file" "devops_eks_policy_json" {
  template = file("${path.module}/../templates/devops_eks_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
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

# Spark : Databricks
data "template_file" "spark_policy_json" {
  count  = var.create_emr_roles ? 0 : 1
  template = file("${path.module}/../templates/spark_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  }
}

# Spark : Databricks
data "template_file" "cross_account_databricks_json" {
  count  = var.create_emr_roles ? 0 : 1
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
  name                 = "tecton-${var.deployment_name}-devops-role"
  tags                 = local.tags
  assume_role_policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.tecton_assuming_account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
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

# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_policy" "devops_eks_policy" {
  name   = "tecton-${var.deployment_name}-devops-eks-policy"
  policy = data.template_file.devops_eks_policy_json.rendered
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


# DEVOPS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "devops_eks_policy_attachment" {
  policy_arn = aws_iam_policy.devops_eks_policy.arn
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
  name                 = "tecton-${var.deployment_name}-eks-management-role"
  tags                 = local.tags
  assume_role_policy   = <<POLICY
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
    role = aws_iam_role.eks_management_role.name
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_role" "eks_node_role" {
  name                 = "tecton-${var.deployment_name}-eks-worker-role"
  tags                 = local.tags
  assume_role_policy   = <<POLICY
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
    role = aws_iam_role.eks_node_role.name
}

# Spark Access Policy : EMR only
resource "aws_iam_policy" "emr_access_policy" {
  count  = var.create_emr_roles ? 0 : 1
  name   = "tecton-${var.deployment_name}-spark-access-policy-emr"
  policy = data.template_file.emr_access_policy_json[0].rendered
  tags   = local.tags
}

# EKS NODE : EMR Only attachment
resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment_emr" {
  count      = var.create_emr_roles ? 0 : 1
  policy_arn = aws_iam_policy.emr_access_policy[0].arn
  role       = aws_iam_role.eks_node_role.name
}

provider "aws" {
  alias = "databricks-account"
}

# Spark Common : Databricks and EMR
resource "aws_iam_policy" "common_spark_policy" {
  provider = aws.databricks-account
  name   = "tecton-${var.deployment_name}-common-spark-policy"
  policy = var.create_emr_roles ? data.template_file.emr_spark_policy_json[0].rendered : data.template_file.spark_policy_json[0].rendered
  tags   = local.tags
}

# Spark Common : Databricks and EMR
resource "aws_iam_role_policy_attachment" "common_spark_policy_attachment" {
  provider    = aws.databricks-account
  policy_arn  = aws_iam_policy.common_spark_policy.arn
  role        = var.create_emr_roles ? (var.emr_spark_role_name != null ? var.emr_spark_role_name : "tecton-${var.deployment_name}-emr-spark-role") : var.spark_role_name
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
  count       = var.create_emr_roles ? 0 : 1
  policy_arn  = aws_iam_policy.cross_account_databricks_policy[0].arn
  role        = aws_iam_role.spark_cross_account_role[0].name
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
