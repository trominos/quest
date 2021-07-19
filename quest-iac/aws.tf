terraform {
  required_version = "~> 0.15.3"
  required_providers {
    aws = {
    source = "hashicorp/aws"
    #  Lock version to prevent unexpected problems
    version = "3.39"
    }
    null = {
    source = "hashicorp/null"
    version = "~> 3.0"
    }
    external = {
    source = "hashicorp/external"
    version = "~> 2.0"
    }
    kubernetes = {
    source = "hashicorp/kubernetes"
    version = "1.13.3"
    }
    
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "<<>>"
  profile                 = var.profile
}
provider "null" {}
provider "external" {}