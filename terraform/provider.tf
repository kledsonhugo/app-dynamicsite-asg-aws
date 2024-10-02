terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.68"
    }
  }

  backend "s3" {
    bucket         = "tf-s3-cp20240202-kledson"
    key            = "terraform.tfstate"
    dynamodb_table = "tf-dynamo-cp20240202-kledson"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}