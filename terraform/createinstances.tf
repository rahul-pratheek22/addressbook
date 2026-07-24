# 1. Dynamically find the latest official CentOS Stream 9 AMI

data "aws_ami" "centos_stream_9" {
  most_recent = true
  owners      = ["aws-marketplace"] # Standard alias for marketplace images

  filter {
    name   = "name"
    values = ["CentOS-Stream-9*"] # Pattern for official CentOS Stream images
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 2. Generate a new TLS Private Key for these instances

resource "tls_private_key" "remote_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 3. Register the public key with AWS to create a Key Pair

resource "aws_key_pair" "remote_key_aws" {
  key_name   = "remote-server-key"
  public_key = tls_private_key.remote_key.public_key_openssh
}

# 4. Save the private key locally as centoskey.pem with restricted permissions

resource "local_file" "private_key_pem" {
  content         = tls_private_key.remote_key.private_key_pem
  filename        = "centoskey.pem"
  file_permission = "400" # Only the owner can read, as required for SSH keys
}

# 5. Provision the two CentOS Remote Servers

resource "aws_instance" "remote_servers" {
  count                  = var.remote_server_count
  ami                    = data.aws_ami.centos_stream_9.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.remote_key_aws.key_name
  subnet_id              = aws_subnet.remote_subnet.id
  vpc_security_group_ids = [aws_security_group.remote_sg.id]

  tags = {
    Name = "remoteserver${count.index + 1}"
  }
}

# 6. Automatically generate the Ansible Inventory file

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl", {
    remote_ips = aws_instance.remote_servers[*].public_ip
  })
  filename        = "inventory"
  file_permission = "0644"
}