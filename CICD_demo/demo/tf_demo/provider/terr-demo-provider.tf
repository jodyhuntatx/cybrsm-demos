provider "conjur" {}

data "conjur_secret" "test_db_uname" {
  name = "DemoVault/CICD/CICD_Secrets/MySQL/username"
}

data "conjur_secret" "test_db_pwd" {
  name = "DemoVault/CICD/CICD_Secrets/MySQL/password"
}

data "conjur_secret" "prod_db_uname" {
  name = "DemoVault/CICD/CICD_Secrets/MSSQLserver/username"
}

data "conjur_secret" "prod_db_pwd" {
  name = "DemoVault/CICD/CICD_Secrets/MSSQLserver/username"
}

output "test_db_pwd" {
  sensitive = false
  value     = "${data.conjur_secret.test_db_pwd.value}"
}

output "test_db_uname" {
  value     = "${data.conjur_secret.test_db_uname.value}"
}

output "prod_db_pwd" {
  sensitive = true
  value     = "${data.conjur_secret.prod_db_pwd.value}"
}

output "prod_db_uname" {
  value     = "${data.conjur_secret.prod_db_uname.value}"
}

