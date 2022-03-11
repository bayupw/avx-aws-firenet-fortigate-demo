# ---------------------------------------------------------------------------------------------------------------------
# AWS Spoke 1
# ---------------------------------------------------------------------------------------------------------------------
module "spoke1" {
  source = "terraform-aviatrix-modules/mc-spoke/aviatrix"

  cloud         = "AWS"
  name          = var.spoke1_vpc
  cidr          = cidrsubnet(var.supernet, 8, 11)
  region        = var.aws_region
  account       = var.aws_account
  transit_gw    = aviatrix_transit_gateway.firenet_gw.gw_name
  instance_size = var.gw_instance_size
  ha_gw         = var.ha_gw
  depends_on    = [aviatrix_transit_gateway.firenet_gw]
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS Spoke 2
# ---------------------------------------------------------------------------------------------------------------------
module "spoke2" {
  source = "terraform-aviatrix-modules/mc-spoke/aviatrix"

  cloud         = "AWS"
  name          = var.spoke2_vpc
  cidr          = cidrsubnet(var.supernet, 8, 12)
  region        = var.aws_region
  account       = var.aws_account
  transit_gw    = aviatrix_transit_gateway.firenet_gw.gw_name
  instance_size = var.gw_instance_size
  ha_gw         = var.ha_gw
  depends_on    = [aviatrix_transit_gateway.firenet_gw]
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS EC2
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}

resource "aws_security_group" "spoke1_instance_sg" {
  name        = "spoke1/sg-instance"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = module.spoke1.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "spoke1/sg-instance"
  }
}

resource "aws_instance" "spoke1_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  subnet_id              = module.spoke1.vpc.private_subnets[0].subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.spoke1_instance_sg.id]

  user_data = <<EOF
#!/bin/bash
sudo sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sudo systemctl restart sshd
echo ec2-user:${var.vm_admin_password} | sudo chpasswd
EOF

  tags = {
    Name = "spoke1-instance"
  }
  #user_data = file("install-nginx.sh")
}

resource "aws_security_group" "spoke2_instance_sg" {
  name        = "spoke2/sg-instance"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = module.spoke2.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "spoke2/sg-instance"
  }
}

resource "aws_instance" "spoke2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  subnet_id              = module.spoke2.vpc.private_subnets[0].subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.spoke2_instance_sg.id]

  user_data = <<EOF
#!/bin/bash
sudo sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sudo systemctl restart sshd
echo ec2-user:${var.vm_admin_password} | sudo chpasswd
EOF

  tags = {
    Name = "spoke2-instance"
  }
  #user_data = file("install-nginx.sh")
}

