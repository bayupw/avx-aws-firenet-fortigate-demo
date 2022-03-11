variable "supernet" {
  type    = string
  default = "10.1.0.0/16"
}

variable "aws_region" {
  type        = string
  default     = "ap-southeast-2"
  description = "AWS region"
}

variable "aws_iam_role" {
  type        = string
  default     = "bootstrap-FortiGate-S3-role"
  description = "Bootstrap IAM role name"
}

variable "aws_iam_policy" {
  type        = string
  default     = "bootstrap-FortiGate-S3-policy"
  description = "Bootstrap IAM policy"
}

variable "bootstrap_bucket" {
  type        = string
  default     = "fortigate-bootstrap-bucket"
  description = "Bootstrap S3 bucket name"
}

variable "aws_account" {
  type        = string
  description = "AWS access account"
}

variable "firenet_vpc" {
  type        = string
  default     = "fg-firenet-vpc"
  description = "Firenet VPC name"
}

variable "spoke1_vpc" {
  type        = string
  default     = "fg-spoke1-vpc"
  description = "Spoke1 VPC name"
}

variable "spoke2_vpc" {
  type        = string
  default     = "fg-spoke2-vpc"
  description = "Spoke2 VPC name"
}

variable "firenet_gw" {
  type        = string
  default     = "fg-firenet-gw"
  description = "Firenet gateway name"
}

variable "firenet_gw_size" {
  type        = string
  default     = "c5.xlarge"
  description = "Transit firenet gateway size"
}

variable "fw_instance_name" {
  type        = string
  default     = "fg-fw-instance"
  description = "Firewall instance name"
}

variable "fw_instance_size" {
  type        = string
  default     = "t2.small"
  description = "Firewall instance size"
}

variable "gw_instance_size" {
  type        = string
  default     = "t2.micro" #hpe "c5.xlarge"
  description = "AWS gateway instance size"
}

variable "enable_gwlb" {
  type        = bool
  default     = false
  description = "Enable AWS Gateway Load Balancer"
}

variable "ha_gw" {
  type        = bool
  default     = false
  description = "Enable HA gateway"
}

variable "fw_admin_password" {
  type        = string
  default     = "Aviatrix123#"
  description = "Firewall admin password"
}

variable "vm_admin_password" {
  type        = string
  default     = "Aviatrix123#"
  description = "VM admin password"
}

locals {
  # Fortigate Firewall bootstrap config
  init_conf = <<EOF
config system admin
    edit admin
        set password ${var.fw_admin_password}
end
config system global
    set hostname fg
    set timezone 04
end
config system interface
    edit port2
    set allowaccess ping https
end
config router static
    edit 1
        set dst 10.0.0.0 255.0.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.firenet_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 2
        set dst 172.16.0.0 255.240.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.firenet_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 3
        set dst 192.168.0.0 255.255.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.firenet_gw.lan_interface_cidr, 1)}
        set device port2
    next
end
config firewall policy
    edit 1
        set name allow-all-LAN-to-LAN
        set srcintf port2
        set dstintf port2
        set srcaddr all
        set dstaddr all
        set action accept
        set schedule always
        set service ALL
        set logtraffic all
        set logtraffic-start enable
    next
end
EOF
}