variable "aws_region" {
    type = string
    description = "The AWS region"
    default = "us-east-1"
}

variable "remote_server_count" {
    type        = number
    description = "Number of remote CentOS instances to provision"
    default     = 2
}

# The AMI and Key Pair paths are handled dynamically via data sources 
# and the tls_private_key resource, so they are not needed as static variables.

