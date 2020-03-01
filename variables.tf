#------------------------------------------------------------------------------#
# Global
#------------------------------------------------------------------------------#

variable "name" {
  description = "Name to be used on resources as identifier"
  type        = string
}

variable "bgp_asn" {
  description = "ASN of customer side"
}

variable "static_routes_only" {
  description = "Wether to configure VPN with static or dynamic routing"
  default     = false
}

variable "vpn_endpoints" {
  description = "List of BGP Customer Gateways and their inside tunnel addresses"
  type = list(object({
    name                = string
    customer_gateway    = string
    tunnel1_inside_cidr = string
    tunnel2_inside_cidr = string
  }))
}

#------------------------------------------------------------------------------#
# Transit Gateway
#------------------------------------------------------------------------------#

variable "transit_gateway_id" {
  description = "ID of Transit Gateway"
  default     = ""
}

variable "transit_gateway_route_table_id" {
  description = "Transit Gateway Route Table to associate with"
  default     = null
}

variable "transit_gateway_propagations" {
  description = "List of Transit Gateway Attachment IDs to propagate into Transit Gateway Route Table"
  default     = []
}

variable "transit_gateway_static_routes" {
  description = "List of Map of Transit Gateway Attachment ID and static route to propagate into Transit Gateway Route Table"
  type = list(object({
    attachment_id = string
    cidr_block    = string
  }))
  default = []
}
