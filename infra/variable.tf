variable "env-prefix" {
  type        = string
  description = "work environment prefix"
}

variable "vpc-cidr-block" {
  type        = string
  description = "VPC CIDR block"
}

variable "public-subnet-cidr-block" {
  type        = string
  description = "CIDR block for public subnet 1"
}

variable "avail-zone" {
  type        = string
  description = "default availability zone"
}


variable "my-ip" {
  type        = string
  description = "my ip for security"
}


variable "rs-database-name" {
  type        = string
  description = "Redshift Database name"
}

variable "rs-master-username" {
  type        = string
  description = "Redshift master username"
}

variable "rs-master-pass" {
  type        = string
  description = "Redshift master password"
}
