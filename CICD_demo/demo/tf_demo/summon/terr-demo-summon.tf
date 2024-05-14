variable "DB_UNAME" {
  description = "Database user name"
  default = "default"
}

variable "DB_PWD" {
  description = "Database password"
  default = "default"
}

output "DB Password" {
  sensitive = true
  value = "${var.DB_PWD}"
}

output "DB Uname" {
  value = "${var.DB_UNAME}"
}

