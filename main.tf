terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.52"
    }
  }
}

# Define Cloudflare provider
provider "cloudflare" {

}