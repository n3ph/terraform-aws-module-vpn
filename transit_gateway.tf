#------------------------------------------------------------------------------#
# Route Table
#------------------------------------------------------------------------------#

resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = var.transit_gateway_id

  tags = {
    Name      = var.name
    Terraform = true
  }

  provider = aws.connect
}

output "transit_gateway_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.main.id
}

#------------------------------------------------------------------------------#
# VPN Association
#------------------------------------------------------------------------------#

resource "aws_ec2_transit_gateway_route_table_association" "main" {
  for_each = toset(var.vpn_endpoints[*].name)

  transit_gateway_attachment_id  = aws_vpn_connection.main[each.value].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id

  provider = aws.connect
}

#------------------------------------------------------------------------------#
# Propagations
#------------------------------------------------------------------------------#

resource "aws_ec2_transit_gateway_route_table_propagation" "main" {
  for_each = toset(var.transit_gateway_propagations)

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id

  provider = aws.connect
}

#------------------------------------------------------------------------------#
# Static Routes
#------------------------------------------------------------------------------#

resource "aws_ec2_transit_gateway_route" "main" {
  for_each = toset(var.transit_gateway_static_routes[*].cidr_block)

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id

  transit_gateway_attachment_id = element([
    for transit_gateway_static_route in var.transit_gateway_static_routes :
    transit_gateway_static_route.attachment_id
    if transit_gateway_static_route.cidr_block == each.value
  ], 0)

  destination_cidr_block = element([
    for transit_gateway_static_route in var.transit_gateway_static_routes :
    transit_gateway_static_route.cidr_block
    if transit_gateway_static_route.cidr_block == each.value
  ], 0)

  provider = aws.connect
}
