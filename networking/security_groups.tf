resource "aws_security_group" "emr_security_group" {
  name        = "tecton-emr-security-group"
  description = "A security group that EMR clusters created by Tecton will use to communicate internally"
  vpc_id      = var.emr_vpc_id
  tags = {
      "tecton-accessible:${var.deployment_name}" = "false",
      "tecton-security-group-emr-usage"       = "master,core&task"
      "Name" = "tecton-emr-security-group"
  }
}
resource "aws_security_group_rule" "emr_security_group_full_egress" {
  description = "Allow full egress for emr to pull pip packages and send metrics"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.emr_security_group.id
  type = "egress"
}
resource "aws_security_group_rule" "emr_security_group_self_ingress" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.emr_security_group.id
  source_security_group_id = aws_security_group.emr_security_group.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group" "emr_service_security_group" {
  name        = "tecton-service-emr-security-group"
  description = "A security group that EMR clusters created by Tecton will use to communicate with EMR services"
  vpc_id      = var.emr_vpc_id
  tags = {
      "tecton-accessible:${var.deployment_name}" = "false",
      "tecton-security-group-emr-usage"       = "service-access"
      "Name" = "tecton-service-emr-security-group"
    }
}

resource "aws_security_group_rule" "emr_security_group_service_ingress" {
  description              = "Allow ingress from emr-service-sg to emr-sg on 8443"
  from_port                = 8443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr_security_group.id
  source_security_group_id = aws_security_group.emr_service_security_group.id
  to_port                  = 8443
  type                     = "ingress"
}

resource "aws_security_group_rule" "emr_service_security_group_ingress" {
  description              = "Allow ingress from emr-sg to emr-service-sg on 9443"
  from_port                = 9443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr_service_security_group.id
  source_security_group_id = aws_security_group.emr_security_group.id
  to_port                  = 9443
  type                     = "ingress"
}

resource "aws_security_group_rule" "emr_service_security_group_egress" {
  description              = "Allow egress from emr-service-sg to emr-sg on 8443"
  from_port                = 8443
  protocol                 = "tcp"
  source_security_group_id        = aws_security_group.emr_security_group.id
  security_group_id = aws_security_group.emr_service_security_group.id
  to_port                  = 8443
  type                     = "egress"
}
