terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.1"
    }
  }
  backend "s3" {
    bucket = "bjgomes-terraform-backend"
    key    = "demo.tfstate"
    region = "us-east-1"
    profile = "vettec20230313"
  }
}


provider "aws" {
  profile = "vettec20230313"
  region  = "us-east-1"
}