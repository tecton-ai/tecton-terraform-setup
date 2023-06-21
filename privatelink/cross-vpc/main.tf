resource "aws_security_group" "cross_vpc_vpc_endpoint" {
  name        = "tecton-services-vpc-endpoint"
  description = "Security group for the accessing Tecton services by cross-vpc vpc endpoint"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.vpc_endpoint_security_group_egress_cidrs
  }
}

resource "aws_security_group_rule" "ingress" {
  description       = "Allow all ingress"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cross_vpc_vpc_endpoint.id
  cidr_blocks       = var.vpc_endpoint_security_group_ingress_cidrs
  to_port           = 65535
  type              = "ingress"
}

resource "aws_vpc_endpoint" "cross_vpc" {
  vpc_id              = var.vpc_id
  service_name        = var.vpc_endpoint_service_name
  security_group_ids  = [aws_security_group.cross_vpc_vpc_endpoint.id]
  subnet_ids          = var.vpc_endpoint_subnet_ids
  vpc_endpoint_type   = "Interface"
  auto_accept         = true
  private_dns_enabled = false
}

resource "aws_route53_zone" "private" {
  name = var.dns_name
  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "cluster_private" {
  name    = var.dns_name
  zone_id = aws_route53_zone.private.id
  type    = "A"

  alias {
    name                   = aws_vpc_endpoint.cross_vpc.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.cross_vpc.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}

data "aws_caller_identity" "current" {}
