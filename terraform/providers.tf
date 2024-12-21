terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.82.1"
    }
  }
  backend "s3" {
    bucket = "mcmcloudresumeremotebackend"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "remote_state_lock"
  }
}

provider "aws" {
  region = "us-east-1"
}