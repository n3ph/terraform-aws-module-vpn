#------------------------------------------------------------------------------#
# Providers
#------------------------------------------------------------------------------#

provider "aws" {
  alias = "connect"
}

#------------------------------------------------------------------------------#
# VPN
#------------------------------------------------------------------------------#

resource "aws_customer_gateway" "main" {
  for_each = toset(var.vpn_endpoints[*].name)

  bgp_asn = var.bgp_asn

  ip_address = element([
    for vpn_endpoint in var.vpn_endpoints :
    vpn_endpoint.customer_gateway
    if vpn_endpoint.name == each.value
  ], 0)

  type = "ipsec.1"

  tags = {
    Name = format("%s-%s", replace(var.name, " ", "-"), each.value)
  }
}

resource "aws_vpn_connection" "main" {
  for_each = toset(var.vpn_endpoints[*].name)

  transit_gateway_id  = var.transit_gateway_id
  customer_gateway_id = aws_customer_gateway.main[each.value].id
  static_routes_only  = var.static_routes_only

  tunnel1_inside_cidr = element([
    for vpn_endpoint in var.vpn_endpoints :
    vpn_endpoint.tunnel1_inside_cidr
    if vpn_endpoint.name == each.value
  ], 0)

  tunnel2_inside_cidr = element([
    for vpn_endpoint in var.vpn_endpoints :
    vpn_endpoint.tunnel2_inside_cidr
    if vpn_endpoint.name == each.value
  ], 0)

  type = "ipsec.1"

  tags = {
    Name = format("%s-%s", replace(var.name, " ", "-"), each.value)
  }
}

output "vpn_connection_configs" {
  value     = aws_vpn_connection.main
  sensitive = true
}

output "transit_gateway_vpn_attachment_ids" {
  value = [
    for name in var.vpn_endpoints[*].name :
    aws_vpn_connection.main[name].transit_gateway_attachment_id
  ]
}

#------------------------------------------------------------------------------#
# Alerting
#------------------------------------------------------------------------------#

resource "aws_sns_topic" "main" {
  name = lower(format("vpn-%s", replace(var.name, " ", "-")))
}

resource "aws_cloudwatch_metric_alarm" "main" {
  for_each = toset(var.vpn_endpoints[*].name)

  alarm_name          = lower(format("vpn-%s-%s", replace(var.name, " ", "-"), each.value))
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TunnelState"
  namespace           = "AWS/VPN"
  period              = "120"
  statistic           = "Minimum"
  threshold           = "1"

  dimensions = {
    VpnId = aws_vpn_connection.main[each.value].id
  }

  alarm_description = "This metric monitors VPN link status"
  alarm_actions     = [aws_sns_topic.main.arn]
  ok_actions        = [aws_sns_topic.main.arn]

  tags = {
    Name = format("%s-%s", replace(var.name, " ", "-"), each.value)
  }
}
