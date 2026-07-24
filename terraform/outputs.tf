output "aws_instance_publicip" {
    value = aws_instance.remote_servers[*].public_ip
    description = "Public IPs of instances"
}