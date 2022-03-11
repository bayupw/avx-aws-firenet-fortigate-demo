# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS Security VPC | firenet vpc
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "firenet_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = var.firenet_vpc
  cidr                 = cidrsubnet(var.supernet, 7, 0)
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | firenet_gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "firenet_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = var.firenet_gw
  vpc_id       = aviatrix_vpc.firenet_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = var.firenet_gw_size
  subnet       = aviatrix_vpc.firenet_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.dev_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection = true
  connected_transit        = true
  single_az_ha             = false
  #enable_active_mesh       = true
  enable_transit_firenet = true

  depends_on = [aviatrix_vpc.firenet_vpc]
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Firewall Instance
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_firewall_instance" "fw_instance" {
  vpc_id          = aviatrix_vpc.firenet_vpc.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.firenet_gw.gw_name
  firewall_name   = "${var.fw_instance_name}-1"
  firewall_image  = "Fortinet FortiGate Next-Generation Firewall"
  firewall_size   = var.fw_instance_size
  egress_subnet   = aviatrix_vpc.firenet_vpc.subnets[1].cidr
  #iam_role              = module.fortigate_bootstrap.aws_iam_role.name
  #bootstrap_bucket_name = module.fortigate_bootstrap.aws_s3_bucket.bucket
  user_data = local.init_conf

  #depends_on = [module.fortigate_bootstrap, time_sleep.wait_bootstrap]
}

# Associate an Aviatrix FireNet Gateway with a Firewall Instance
resource "aviatrix_firewall_instance_association" "fw_instance_assoc" {
  vpc_id          = aviatrix_firewall_instance.fw_instance.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.firenet_gw.gw_name
  instance_id     = aviatrix_firewall_instance.fw_instance.instance_id
  firewall_name   = aviatrix_firewall_instance.fw_instance.firewall_name
  lan_interface   = aviatrix_firewall_instance.fw_instance.lan_interface
  #management_interface = aviatrix_firewall_instance.dev_ew_fw_instance.management_interface
  egress_interface = aviatrix_firewall_instance.fw_instance.egress_interface
  attached         = true
}

# Create an Aviatrix FireNet
resource "aviatrix_firenet" "firenet" {
  vpc_id                               = aviatrix_firewall_instance.fw_instance.vpc_id
  inspection_enabled                   = true
  egress_enabled                       = false
  keep_alive_via_lan_interface_enabled = false
  manage_firewall_instance_association = false

  depends_on = [
    aviatrix_firewall_instance_association.fw_instance_assoc
  ]
}

# Spoke1 FireNet Policy
resource "aviatrix_transit_firenet_policy" "spoke1_firenet_policy" {
  transit_firenet_gateway_name = aviatrix_transit_gateway.firenet_gw.gw_name
  inspected_resource_name      = "SPOKE:${module.spoke1.spoke_gateway.gw_name}"
  depends_on                   = [module.spoke1]
}

# Spoke2 FireNet Policy
resource "aviatrix_transit_firenet_policy" "spoke2_firenet_policy" {
  transit_firenet_gateway_name = aviatrix_transit_gateway.firenet_gw.gw_name
  inspected_resource_name      = "SPOKE:${module.spoke2.spoke_gateway.gw_name}"
  depends_on                   = [module.spoke2]
}