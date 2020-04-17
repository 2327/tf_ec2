variable "aws-region" {
  default     = "us-west-2"
  description = "Default Amazon region"
}

variable "availability_zone_names" {
  type    = string
  default = "us-west-2a"
}

variable "ami_owners" {
  description = "The list of owners used to select the AMI of Pritunl instances."
  type        = list(string)
  default     = ["self"]
}

variable "instance_type" {
  description = "The type of EC2 Instances to run for each node in the cluster (e.g. t2.micro)."
  type        = string
  default     = "t2.micro"
}

variable "root_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default     = 8
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "root_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default     = "gp2"
}

variable "data_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default     = 2
}

variable "data_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "data_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default     = "gp2"
}

variable "health_check_type" {
  description = "Controls how health checking is done. Must be one of EC2 or ELB."
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Time, in seconds, after instance comes into service before checking health."
  default     = 60
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

