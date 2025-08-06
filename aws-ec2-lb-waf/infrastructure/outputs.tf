output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "cloudwatch_log_group_waf" {
  description = "CloudWatch log group for WAF"
  value       = aws_cloudwatch_log_group.waf.name
}

output "cloudwatch_log_group_alb" {
  description = "CloudWatch log group for ALB"
  value       = aws_cloudwatch_log_group.alb.name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "health_check_url" {
  description = "URL for health check endpoint"
  value       = "http://${aws_lb.main.dns_name}/health"
}

output "api_base_url" {
  description = "Base URL for API endpoints"
  value       = "http://${aws_lb.main.dns_name}/api"
}

# Security Group IDs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

# Key Pair
output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.main.key_name
}

# Launch Template
output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

# WAF IP Sets
output "allowed_ip_set_arn" {
  description = "ARN of the allowed IP set"
  value       = aws_wafv2_ip_set.allowed_ips.arn
}

output "blocked_ip_set_arn" {
  description = "ARN of the blocked IP set"
  value       = aws_wafv2_ip_set.blocked_ips.arn
}

# Testing Information
output "testing_commands" {
  description = "Commands to test the setup"
  value = {
    basic_connectivity = "curl http://${aws_lb.main.dns_name}"
    health_check      = "curl http://${aws_lb.main.dns_name}/health"
    api_status        = "curl http://${aws_lb.main.dns_name}/api/status"
    instance_info     = "curl http://${aws_lb.main.dns_name}/api/instance-info"
    sql_injection_test = "curl 'http://${aws_lb.main.dns_name}/search?q=%27%20OR%201=1%20--'"
    xss_test          = "curl -X POST -H 'Content-Type: application/json' -d '{\"comment\":\"<script>alert(\\\"XSS\\\")</script>\"}' http://${aws_lb.main.dns_name}/comment"
  }
}
