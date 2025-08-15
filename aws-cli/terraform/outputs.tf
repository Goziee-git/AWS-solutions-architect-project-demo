# outputs.tf - Output value definitions

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "availability_zone" {
  description = "Availability zone used"
  value       = local.availability_zone
}

# Internet Gateway Output
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Route Table Output
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# Security Group Output
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_server.id
}

# EC2 Instance Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

# AMI Output
output "ami_id" {
  description = "ID of the AMI used"
  value       = data.aws_ami.amazon_linux.id
}

# Connection Information
output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.web_server.public_ip}"
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}

# Resource Summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    vpc_id              = aws_vpc.main.id
    public_subnet_id    = aws_subnet.public.id
    private_subnet_id   = aws_subnet.private.id
    internet_gateway_id = aws_internet_gateway.main.id
    security_group_id   = aws_security_group.web_server.id
    instance_id         = aws_instance.web_server.id
    public_ip          = aws_instance.web_server.public_ip
    web_url            = "http://${aws_instance.web_server.public_ip}"
  }
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost (USD)"
  value = {
    instance_cost = var.instance_type == "t2.micro" ? "~$8.50 (Free tier: 750 hours/month)" : "Variable based on instance type"
    vpc_cost      = "Free"
    data_transfer = "First 1GB free, then $0.09/GB out"
    total_note    = "Costs may vary by region and usage"
  }
}

# Monitoring URLs
output "monitoring_urls" {
  description = "URLs for monitoring and management"
  value = {
    ec2_console = "https://${var.aws_region}.console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}#Instances:instanceId=${aws_instance.web_server.id}"
    vpc_console = "https://${var.aws_region}.console.aws.amazon.com/vpc/home?region=${var.aws_region}#vpcs:VpcId=${aws_vpc.main.id}"
    cloudwatch  = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#metricsV2:graph=~();search=${aws_instance.web_server.id}"
  }
}
