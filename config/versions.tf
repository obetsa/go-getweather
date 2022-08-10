terraform {

  cloud {
    organization = "go-getweather"

    workspaces {
      name = "go"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.28.0"
    }
  }

  required_version = ">= 1.1.0"
}