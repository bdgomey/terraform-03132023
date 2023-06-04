variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.0.0/16"
}

variable "instance_tenancy" {
  type        = string
  description = "Instance Tenancy"
  default     = "default"
}

variable "public_subnet_count" {
  type        = number
  description = "Count of public subnets that I want created"
}

variable "private_subnet_count" {
  type        = number
  description = "Count of public subnets that I want created"
}


variable "subnet_bits" { # i.e. if the subnet_bits variable is 8 and my vpc cidr is 10.0.0.0/16, this will add 8 to the cidr making it a 10.0.0.0/24 for the subnet
  type        = number
  description = "subnet bits I want added to the vpc cidr block to create my subnet cidr block"
  default     = 8
}

variable "availability_zone" {
  type        = list(string)
  description = "the availability zone"
  default     = ["us-east-1a", "us-east-1b"]
}