variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "enabled" {
  description = "Enable or disable the deployment"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "cmmx"
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
 description = "CIDR blocks for public subnets"
 type        = list(string)
 default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
 description = "CIDR blocks for private subnets"
 type        = list(string)
 default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# 4. GIT/Automation
variable "GIT_HTTPS_REPO" {
  description = "Git HTTPS repository containing the Terraform code."
  type        = string
  default     = ""
}

variable "GIT_REPO" {
  description = "Git repository containing the Terraform code."
  type        = string
  default     = ""
}

variable "GIT_BRANCH" {
  description = "Git branch containing the Terraform code."
  type        = string
  default     = ""
}

# CloudWatch Logging
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "enable_function_urls" {
  description = "Enable or disable the creation of public Lambda Function URLs"
  type        = bool
  default     = true
}
