# variables.tf - Input variable definitions

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-simple-architecture"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "terraform-user"
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
  
  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid IPv4 CIDR block."
  }
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition = contains([
      "t2.nano", "t2.micro", "t2.small", "t2.medium", "t2.large",
      "t3.nano", "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 access"
  type        = string
  
  validation {
    condition     = length(var.key_pair_name) > 0
    error_message = "Key pair name cannot be empty."
  }
}

# Security Configuration
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access (default: anywhere)"
  type        = string
  default     = "0.0.0.0/0"
  
  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "Allowed SSH CIDR must be a valid IPv4 CIDR block."
  }
}

variable "allowed_http_cidr" {
  description = "CIDR block allowed for HTTP access (default: anywhere)"
  type        = string
  default     = "0.0.0.0/0"
  
  validation {
    condition     = can(cidrhost(var.allowed_http_cidr, 0))
    error_message = "Allowed HTTP CIDR must be a valid IPv4 CIDR block."
  }
}

# Feature Flags
variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2 instance"
  type        = bool
  default     = false
}

variable "enable_termination_protection" {
  description = "Enable termination protection for EC2 instance"
  type        = bool
  default     = false
}
