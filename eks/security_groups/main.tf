# RDS
resource "aws_security_group" "postgres_metadata_db_security" {
  name = "${var.deployment_name}-postgres_metadata_db_security"

  description = "Tecton RDS postgres security group"
  vpc_id      = var.cluster_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allow EKS worker nodes to talk to RDS postgres DB"
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
  vpc_id      = var.cluster_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge( var.tags,
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

locals {
  _listener_ports = {
    # These must match the nodePorts of the Ingress service
    # They match Tecton's public ingress
    # plaintext is just for redirection to https
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

# Worker Nodes
resource "aws_security_group" "worker_node" {
  name        = "${var.deployment_name}-worker-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.cluster_vpc_id

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
  cidr_blocks       = var.ip_whitelist
  description       = "Access from the NLB to the K8s Ingress port(s)"
}
