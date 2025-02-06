
data "aws_iam_policy_document" "tecton_elasticache_manager_policy_document" {
  statement {
    sid    = "AllowTectonCrudElastiCache"
    effect = "Allow"
    actions = [
      "elasticache:CreateCacheCluster",
      "elasticache:DescribeCacheClusters",
      "elasticache:ModifyCacheCluster",
      "elasticache:DeleteCacheCluster",
      "elasticache:AddTagsToResource",
      "elasticache:RemoveTagsFromResource",
      "elasticache:CreateSnapshot",
      "elasticache:DeleteSnapshot",
      "elasticache:ModifySnapshotAttribute",
      "elasticache:DescribeSnapshots",
      "elasticache:CopySnapshot",
      "elasticache:DescribeServiceUpdates",
      "elasticache:ListAllowedNodeTypeModifications",
      "elasticache:ListTagsForResource",
      "elasticache:ModifyReplicationGroup",
      "elasticache:CreateReplicationGroup",
      "elasticache:DeleteReplicationGroup",
      "elasticache:DescribeReplicationGroups",
      "elasticache:DescribeReplicationGroup",
      "elasticache:ModifyReplicationGroupShardConfiguration",
      "elasticache:DescribeEvents",
      "elasticache:FailoverGlobalReplicationGroup",
      "elasticache:AuthorizeCacheSecurityGroupIngress",
      "elasticache:CreateCacheSecurityGroup",
      "elasticache:DeleteCacheSecurityGroup",
      "elasticache:DescribeCacheSecurityGroups",
      "elasticache:DescribeEngineVersions",
      "elasticache:DescribeReservedCacheNodesOfferings",
      "elasticache:DescribeCacheEngineVersions",
      "elasticache:DescribeReservedCacheNodes",
      "elasticache:DescribeCacheSubnetGroups",
      "elasticache:DescribeCacheParameters",
      "elasticache:DescribeCacheParameterGroups",
      "elasticache:CreateCacheParameterGroup",
      "elasticache:DeleteCacheParameterGroup",
      "elasticache:ModifyCacheParameterGroup",
      "elasticache:ResetCacheParameterGroup",
      "elasticache:DescribeUserGroups",
      "elasticache:DescribeUsers",
      "elasticache:AuthorizeCacheSecurityGroupIngress",
      "elasticache:RevokeCacheSecurityGroupIngress",
      "elasticache:AuthorizeCacheSecurityGroupEgress",
      "elasticache:RevokeCacheSecurityGroupEgress",
      "elasticache:DescribeCacheEngineVersions",]
    resources = ["*"]

    # Condition #1: The name or replication group ID must start with "tec"
    condition {
      test     = "StringLikeIfExists"
      variable = "elasticache:ClusterName"
      values   = ["tec-*"]
    }

    condition {
      test     = "StringLikeIfExists"
      variable = "elasticache:ReplicationGroupId"
      values   = ["tec-*"]
    }

    # Condition #2: Must be placed in the specified subnet group
    condition {
      test     = "StringEqualsIfExists"
      variable = "elasticache:SubnetGroupName"
      values   = [aws_elasticache_subnet_group.tecton_elasticache_subnet_group]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_policy_document" {
  statement {
    sid    = "AllowTectonCrudElastiCache"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tecton_cloudwatch_management_policy" {
  name        = "tecton-elasticache-management-policy"
  description = "Policy for managing Elasticache resources"
  policy = data.aws_iam_policy_document.cloudwatch_policy_document.json
}

resource "aws_iam_policy_attachment" "tecton_cloudwatch_policy_attachment" {
  name       = "Tecton cloudwatch policy attachment"
  policy_arn = aws_iam_policy.tecton_cloudwatch_management_policy.arn
  roles = [var.cross_account_role_name]
}


resource "aws_iam_policy" "tecton_elasticache_management_policy" {
  name        = "tecton-elasticache-management-policy"
  description = "Policy for managing Elasticache resources"
  policy = data.aws_iam_policy_document.tecton_elasticache_manager_policy_document.json
}

resource "aws_iam_policy_attachment" "tecton_elasticache_management_policy_attachment" {
  name       = "Tecton cache management policy attachment"
  policy_arn = aws_iam_policy.tecton_elasticache_management_policy.arn
  roles = [var.cross_account_role_name]
}

