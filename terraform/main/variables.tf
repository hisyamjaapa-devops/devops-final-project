variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "syam9-devops-final"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "admin_cidr" {
  description = "Your current public IPv4 in CIDR notation, e.g. 203.0.113.10/32"
  type        = string
}

variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "controller_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "monitoring_instance_type" {
  type    = string
  default = "t3.small"
}
