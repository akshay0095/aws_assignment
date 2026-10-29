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

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "scale_out_cpu_threshold" {
  type        = number
  default     = 70
}

variable "scale_in_cpu_threshold" {
  type        = number
  default     = 30
}

variable "db_engine_version" {
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type        = string
  default     = "appadmin"
}

variable "db_skip_final_snapshot" {
  type        = bool
  default     = true
}
