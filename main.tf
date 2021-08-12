# ************************** Networks setup ************************************

## Management network

### Create VPC

resource "aws_vpc" "this" {
  cidr_block = var.mgmt_subnet_cidr
  tags = {
    Name = format("%s-mgmt-vpc", var.project_name)
  }
}
### Create subnets

#### Public subnet

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.mgmt_public_subnet_cidr
  availability_zone       = var.project_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s-mgmt-public-subnet", var.project_name)
  }
}
#### Private subnet

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.mgmt_private_subnet_cidr
  availability_zone = var.project_availability_zone

  tags = {
    Name = format("%s-mgmt-private-subnet", var.project_name)
  }
}

### Create Internet Gateway and attach to vpc

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-mgmt-igw", var.project_name)
  }
}

### Route table

resource "aws_route_table" "igw_route_table" {
  vpc_id = aws_vpc.this.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = format("%s-igw-route-table", var.project_name)
  }
}

resource "aws_route_table_association" "igw_route_table_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.igw_route_table.id
}

### Create NAT gateway

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.this]

  tags = {
    Name = format("%s-ngw", var.project_name)
  }

}

resource "aws_route_table" "ngw_route_table" {
  vpc_id     = aws_vpc.this.id
  depends_on = [aws_nat_gateway.this]


  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = format("%s-ngw-route-table", var.project_name)
  }
}
resource "aws_route_table_association" "ngw_route_table_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.ngw_route_table.id
}

### Associate eip


resource "aws_eip" "nat" {
  vpc        = true
  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = format("%s-nat-eip", var.project_name)
  }
}


## Security groups

resource "aws_security_group" "common" {
  name        = "common_sg"
  description = "Allow ssh,icmp"
  vpc_id      = aws_vpc.this.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ALL ICMP - IPv4"
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-common-sg", var.project_name)
  }
}
resource "aws_security_group" "bastion" {
  name        = "bastion_sg"
  description = "Allow web"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = format("%s-bastion-sg", var.project_name)
  }
}
resource "aws_security_group" "web" {
  name        = "web_sg"
  description = "Allow web"
  vpc_id      = aws_vpc.this.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-web-sg", var.project_name)
  }
}
resource "aws_security_group" "private_subnet" {
  name        = "private_subnet_sg"
  description = "Allow private subnet"
  vpc_id      = aws_vpc.this.id
  ingress {
    description     = "all from proxy web"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.bastion.id, aws_security_group.web.id]
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-private-subnet-sg", var.project_name)
  }
}
resource "aws_security_group" "public_subnet" {
  name        = "public_subnet_sg"
  description = "Allow public subnet"
  vpc_id      = aws_vpc.this.id
  ingress {
    description     = "all from public subnet security group"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  tags = {
    Name = format("%s-public-subnet-sg", var.project_name)
  }
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
}

resource "tls_private_key" "project" {
  algorithm = "RSA"
}


resource "aws_key_pair" "bastion_ssh_key" {
  key_name   = "${var.project_name}-bastion-keypair"
  public_key = tls_private_key.bastion.public_key_openssh
}
resource "aws_key_pair" "project_ssh_key" {
  key_name   = "${var.project_name}-project-keypair"
  public_key = tls_private_key.project.public_key_openssh
}

# ************************** Floating Ips *******************************************

## Bastion

resource "aws_eip" "bastion_floatingip" {
  vpc = true
}

locals {
  bastion_floating_ip = aws_eip.bastion_floatingip.public_ip
}

data "http" "generic_user_data_template" {
  url = var.generic_user_data_file_url
}
