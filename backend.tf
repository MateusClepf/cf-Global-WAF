
terraform {
  cloud {
    organization = "cf-lab-terraform"

    workspaces {
      name = "cf-Global-WAF"
    }
  }
}




