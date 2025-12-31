variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "cmmx"
}

variable "ecr_repo_name" {
  description = "ECR Repository Name"
  type        = string
  default     = "cmmx"
}

variable "image_tag" {
  description = "Docker Image Tag"
  type        = string
  default     = "latest"
}

variable "db_username" {
  description = "Database Master Username"
  type        = string
  default     = "postgres"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "Availability Zones for the VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_private_subnets" {
  description = "Private subnets for the VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnets for the VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}
