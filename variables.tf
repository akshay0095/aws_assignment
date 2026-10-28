variable "region" {
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  type        = string
  default     = "webapp"
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "two azs min are required for high A."
  }
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}
