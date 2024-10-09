# Restricts egress from rift compute to only allowed domains.
# Activated with var.use_network_firewall = true

locals {
  default_allowed_egress_domains = [
    format("%s.tecton.ai", var.cluster_name), # tecton control plane for this cluster
    "tecton.chronosphere.io",                 # Metrics
    "packages.fluentbit.io",
    ".ecr.aws",
    ".amazonaws.com",
    ".aws.amazon.com",
    # Crowdstrike
    ".crowdstrike.com",
    ".cloudsink.net",
    ".githubusercontent.com",
    "crowdstrike.github.io",
  ]

}

resource "aws_networkfirewall_firewall" "rift_egress" {
  count                    = var.use_network_firewall ? 1 : 0
  delete_protection        = false
  firewall_policy_arn      = aws_networkfirewall_firewall_policy.rift_egress[0].arn
  name                     = "tecton-rift-egress-firewall"
  subnet_change_protection = false
  tags                     = {}
  tags_all                 = {}
  vpc_id                   = aws_vpc.rift.id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall_subnet
    content {
      subnet_id       = subnet_mapping.value.id
      ip_address_type = "IPV4"
    }
  }

}


resource "aws_networkfirewall_firewall_policy" "rift_egress" {
  count = var.use_network_firewall ? 1 : 0
  name  = "tecton-rift-egress-firewall-policy"
  firewall_policy {
    stateful_default_actions           = ["aws:alert_established", "aws:drop_established"]
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:pass"]
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateful_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.rift_compute_egress_allowed_domains[0].arn
    }
  }
}


resource "aws_networkfirewall_rule_group" "rift_compute_egress_allowed_domains" {
  count    = var.use_network_firewall ? 1 : 0
  capacity = 500
  name     = "egress-allowed-domains-rift"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_string = null
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = concat(local.default_allowed_egress_domains, var.additional_allowed_egress_domains)
      }
    }
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}

module "firewall_subnet_cidrs" {
  source          = "hashicorp/subnets/cidr"
  version         = "1.0.0"
  base_cidr_block = local.vpc_cidr
  networks = [for az in var.subnet_azs :
    {
      name     = "firewall-${az}"
      new_bits = floor((32 - local.base_cidr_mask) / length(var.subnet_azs)) + 2
    }
  ]
}

resource "aws_subnet" "firewall_subnet" {
  for_each = var.use_network_firewall ? module.firewall_subnet_cidrs.network_cidr_blocks : {}
  vpc_id            = aws_vpc.rift.id
  availability_zone = join("-", slice(split("-", each.key), 1, length(split("-", each.key))))
  cidr_block        = each.value
  tags = {
    Name = format("tecton-rift-firewall-%s", each.key)
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route_table" "firewall_route_table" {
  count  = var.use_network_firewall ? 1 : 0
  vpc_id = aws_vpc.rift.id
  tags = {
    Name = "tecton-rift-firewall-route-table"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route_table" "igw_route_table" {
  count  = var.use_network_firewall ? 1 : 0
  vpc_id = aws_vpc.rift.id
  tags = {
    Name = "tecton-rift-firewall-igw-route-table"
  }


}

resource "aws_route_table_association" "igw_route_table_assoc" {
  count          = var.use_network_firewall ? 1 : 0
  gateway_id     = aws_internet_gateway.rift.id
  route_table_id = aws_route_table.igw_route_table[0].id
}

resource "aws_route_table_association" "firewall_subnet_route_table_association" {
  for_each       = aws_subnet.firewall_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.firewall_route_table[0].id
}

locals {
  networkfirewall_endpoints = var.use_network_firewall ? {
    for i in aws_networkfirewall_firewall.rift_egress[0].firewall_status[0].sync_states :
    i.availability_zone => i.attachment[0].endpoint_id
  } : {}
}

# Route internet traffic to firewall from public subnet
resource "aws_route" "public_subnet_route_to_firewall" {
  count                  = var.use_network_firewall ? 1 : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.networkfirewall_endpoints[keys(local.networkfirewall_endpoints)[0]]
}

# Route internet traffic back to firewall from igw
resource "aws_route" "igw_route_to_firewall_to_public_subnet" {
  for_each               = var.use_network_firewall ? aws_subnet.public : {}
  route_table_id         = aws_route_table.igw_route_table[0].id
  destination_cidr_block = each.value.cidr_block
  vpc_endpoint_id        = local.networkfirewall_endpoints[keys(local.networkfirewall_endpoints)[0]]
}

# Route outgoing internet traffic to igw from firewall
resource "aws_route" "firewall_route_to_igw" {
  count                  = var.use_network_firewall ? 1 : 0
  route_table_id         = aws_route_table.firewall_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rift.id
}
