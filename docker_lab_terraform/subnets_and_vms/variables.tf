# e.g. export TF_VAR_key_name="..."
variable "key_name" {
  description = "My AWS SSH key name"
  type        = string
}

# e.g. export TF_VAR_main_vpc_id="vpc-..."
variable "main_vpc_id" {
  description = "main VPC ID"
  type        = string
}

# e.g. export TF_VAR_igw_id="igw-..."
variable "igw_id" {
  description = "main VPC internet gateway ID"
  type        = string
}

# e.g. export TF_VAR_ssh_ip="..."
variable "ssh_ip" {
  description = "My home IP address"
  type        = string
}
