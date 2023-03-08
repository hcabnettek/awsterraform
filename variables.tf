variable "instance_name" {
  description = "Name of ec2 instance"
  type        = string
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-0574da719dca65348" # Ubuntu 20.04 LTS // us-east-1
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "db_user" {
  description = "username for database"
  type        = string
  default     = "foo"
}

variable "db_pass" {
  description = "password for database"
  type        = string
  sensitive   = true
}

variable "ssh_key_private" {
  description = "Path to the private key used to access instances via ssh"
  type        = string
  default     = "/Users/christopherk/.ssh/bookstore-key.pem"
}
variable "playbook_path" {
  description = "Path to ansible playbook to be executed with the created host as inventory"
  type        = string
  default     = "deploy_nginx/playbook.yml"
}