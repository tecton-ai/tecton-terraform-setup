locals {
  _listener_ports = {
    # These must match the nodePorts of the Ingress service. They match Tecton's public ingress.
    # The plaintext is just for redirection to https.
    plaintext = {
      port     = 31080
      protocol = "TCP"
    }
    tls = {
      port     = 31443
      protocol = "TLS"
    }
  }
}

# RDS
resource "aws_security_group" "postgres_metadata_db_security" {
  name = "${var.deployment_name}-postgres_metadata_db_security"

  description = "Tecton RDS postgres security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "Allow EKS worker nodes to talk to RDS postgres DB"
    security_groups = [aws_security_group.worker_node.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.deployment_name}-postgres_metadata_db_security"
    }
  )
}

# EKS Main Group
resource "aws_security_group" "tecton_eks_cluster" {
  name        = var.deployment_name
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags,
    {
      Name = var.deployment_name
    }
  )
}

resource "aws_security_group_rule" "public-ingress-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow the whole world to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.tecton_eks_cluster.id
  to_port           = 443
  type              = "ingress"
}

# Worker Nodes
resource "aws_security_group" "worker_node" {
  name        = "${var.deployment_name}-worker-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name"                                         = "${var.deployment_name}-worker-node",
      "kubernetes.io/cluster/${var.deployment_name}" = "owned"
    }
  )
}

resource "aws_security_group_rule" "worker-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker_node.id
  source_security_group_id = aws_security_group.worker_node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node.id
  source_security_group_id = aws_security_group.tecton_eks_cluster.id
  to_port                  = 65535
  type                     = "ingress"

}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tecton_eks_cluster.id
  source_security_group_id = aws_security_group.worker_node.id
  to_port                  = 443
  type                     = "ingress"

}

resource "aws_security_group_rule" "lb_to_eks_ingress_port" {
  for_each          = local._listener_ports
  security_group_id = aws_security_group.worker_node.id
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "TCP"
  # For the public NLB, we also whitelist the public NAT gateway IPs because Tecton requests from the VPC
  # will go through the coresponding NAT gateway first.
  # For the private NLB, we also whitelist the private CIDR block(s) of the VPC because
  # the Tecton requests from the VPC will be routed directly to the NLB.
  cidr_blocks = var.allowed_CIDR_blocks == null ? ["0.0.0.0/0"] : (
    var.eks_ingress_load_balancer_public ?
    concat(var.allowed_CIDR_blocks, [for ip in var.nat_gateway_ips : format("%s/32", ip)]) :
    concat(var.allowed_CIDR_blocks, var.vpc_cidr_blocks)
  )


  description = "Access from the NLB to the K8s Ingress port(s)"
}

resource "aws_security_group" "eks_ingress_vpc_endpoint_security_group" {
  count = var.enable_eks_ingress_vpc_endpoint ? 1 : 0

  name = format(
    "%s-eks-ingress-vpc-endpoint-security-group", var.deployment_name,
  )
  description = "EKS Ingress VPC Endpoint Security group for in-VPC communication"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name" = format(
        "%s-eks-ingress-vpc-endpoint-security-group", var.deployment_name,
      ),
      format(
        "kubernetes.io/cluster/%s", var.deployment_name,
      ) = "owned",
    }
  )
}

resource "aws_security_group_rule" "eks_ingress_vpc_endpoint_security_group_ingress" {
  count = var.enable_eks_ingress_vpc_endpoint ? 1 : 0

  description              = "Allow all ingress from EKS worker node security group"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_ingress_vpc_endpoint_security_group[0].id
  source_security_group_id = aws_security_group.worker_node.id
  to_port                  = 65535
  type                     = "ingress"
}
