resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "demo_vpc"
  }
}

resource "aws_subnet" "public_demo_subnet_1A" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "demo_public_1A"
  }
}

resource "aws_subnet" "public_demo_subnet_1B" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "demo_public_1B"
  }
}

resource "aws_subnet" "private_demo_subnet_1A" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name = "demo_private_1A"
  }
}

resource "aws_subnet" "private_demo_subnet_1B" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Name = "demo_private_1B"
  }
}

resource "aws_internet_gateway" "demo_internet_gateway" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_igw"
  }
}

resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_public_rt"
  }
}

resource "aws_route_table" "demo_private_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_private_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.demo_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demo_internet_gateway.id
}

resource "aws_route_table_association" "demo_public_assoc-1A" {
  subnet_id      = aws_subnet.public_demo_subnet_1A.id
  route_table_id = aws_route_table.demo_public_rt.id
}

resource "aws_route_table_association" "demo_public_assoc-1B" {
  subnet_id      = aws_subnet.public_demo_subnet_1B.id
  route_table_id = aws_route_table.demo_public_rt.id
}

resource "aws_route_table_association" "demo_private_assoc-1A" {
  subnet_id      = aws_subnet.private_demo_subnet_1A.id
  route_table_id = aws_route_table.demo_private_rt.id
}

# resource "aws_route_table_association" "demo_private_assoc-1B" {
#   subnet_id      = aws_subnet.private_demo_subnet_1B.id
#   route_table_id = aws_route_table.demo_private_rt.id
# }

resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.demo_internet_gateway]
}

#NAT gateway part
# using public b1 for nat gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_demo_subnet_1B.id

  tags = {
    Name = "NAT-GW"
  }

  depends_on = [aws_internet_gateway.demo_internet_gateway]
}

#rt for NAT
resource "aws_route_table" "demo_nat_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_nat_rt"
  }
}

resource "aws_route" "nat_route" {
  route_table_id         = aws_route_table.demo_nat_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw.id
}

resource "aws_route_table_association" "demo_nat_assoc-1B" {
  subnet_id      = aws_subnet.private_demo_subnet_1B.id
  route_table_id = aws_route_table.demo_nat_rt.id
}


resource "aws_security_group" "demo_sg" {
  name        = "demo_sg"
  description = "demo security group for web traffic"
  vpc_id      = aws_vpc.demo_vpc.id

#for dockerized application api calls
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #https
  ingress {
    from_port   = 433
    to_port     = 433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "demo_auth" {
  key_name   = "demokey"
  public_key = file("~/.ssh/demokey.pub")
}

resource "aws_instance" "public_demo_node" {
  instance_type               = "t2.micro"
  ami                         = data.aws_ami.demo_ami.id
  key_name                    = aws_key_pair.demo_auth.id
  vpc_security_group_ids      = [aws_security_group.demo_sg.id]
  subnet_id                   = aws_subnet.public_demo_subnet_1B.id
  user_data                   = file("userdata.tpl")

  # root_block_device {
  #   volume_size = 8
  # }

  tags = {
    Name = "public-demo-node"
  }
}

resource "aws_instance" "private_demo_node" {
  instance_type               = "t2.micro"
  ami                         = data.aws_ami.demo_ami.id
  key_name                    = aws_key_pair.demo_auth.id
  vpc_security_group_ids      = [aws_security_group.demo_sg.id]
  subnet_id                   = aws_subnet.private_demo_subnet_1B.id
  user_data                   = file("userdata.tpl")

  # root_block_device {
  #   volume_size = 8
  # }

  tags = {
    Name = "private-demo-node"
  }
}