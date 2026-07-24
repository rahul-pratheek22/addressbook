# 1. Fetch the VPC

data "aws_vpc" "custom_vpc" {
  filter {
    name   = "tag:Name"
    values = ["Mycustomvpc"]
  }
}

# 2. Use the fetched VPC ID to create a new subnet

resource "aws_subnet" "remote_subnet" {
  vpc_id     = data.aws_vpc.custom_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Remote-Subnet"
  }
}

# Fetch existing route table

data "aws_route_table" "custom_rt" {
    filter {
        name = "tag:Name"
        values = ["custom_rt"]
    }
}

# Associate the fetched route table to new subnet

resource "aws_route_table_association" "associate_rt"{
    subnet_id = aws_subnet.remote_subnet.id
    route_table_id = data.aws_route_table.custom_rt.id
}

# Fetch the existing Control Server Security Group by Name

data "aws_security_group" "control_server_sg" {
  filter {
    name   = "group-name"
    values = ["JenkinsAnsibleServer-SG"]
  }
  vpc_id = data.aws_vpc.custom_vpc.id
}


# Create new security group for remote servers

resource "aws_security_group" "remote_sg" {
    name        = "RemoteServers-SG"
    description = "Security group for remote CentOS servers"
    vpc_id      = data.aws_vpc.custom_vpc.id

    # Secure SSH Access: Allowing ONLY your existing Jenkins control server data block to connect
    
    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = [data.aws_security_group.control_server_sg.id]
    }
    
    # HTTP Access: Allow port 80 from Anywhere
    
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

    # Outbound: Allow all traffic
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        }
    
    tags = {
        Name = "remote-sg"
    }
}

