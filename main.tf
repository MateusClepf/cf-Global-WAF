
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Define Cloudflare provider
provider "cloudflare" {
    #Token is set an an environment variable in terraform cloud
}