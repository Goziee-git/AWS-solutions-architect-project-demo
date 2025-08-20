# compute.tf - EC2 and compute resources

# User data script for web server setup
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    vpc_cidr     = var.vpc_cidr
  }))
}

resource "aws_key_pair" "web_key" {
  key_name   = var.key_pair_name
  public_key = file("~/.ssh/terraform-keypair.pub")
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-keypair"
  })
}

# Create EC2 instance
resource "aws_instance" "web_server" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.web_key.key_name
  vpc_security_group_ids  = [aws_security_group.web_server.id]
  subnet_id               = aws_subnet.public.id
  user_data               = local.user_data
  
  monitoring                           = var.enable_detailed_monitoring
  disable_api_termination             = var.enable_termination_protection
  instance_initiated_shutdown_behavior = "stop"

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${var.project_name}-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-server"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Create Elastic IP (optional - uncomment if needed)
# resource "aws_eip" "web_server" {
#   instance = aws_instance.web_server.id
#   domain   = "vpc"
#   
#   tags = merge(local.common_tags, {
#     Name = "${var.project_name}-eip"
#   })
#   
#   depends_on = [aws_internet_gateway.main]
# }
