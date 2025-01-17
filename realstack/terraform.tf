terraform {

  backend "s3" {
    bucket         = "test-aw-real-aws-nonprod-tf-states-critical"
    key            = "test-aw-real-aws-nonprod-account.terraform.tfstates"
    encrypt        = true
    region         = "us-east-1"
    dynamodb_table = "test-aw-real-nonprod-tf-locks-critical"
    profile        = "aw-test"
    #skip_credentials_validation = true
    #skip_metadata_api_check     = true
    #skip_region_validation = true
    #skip_requesting_account_id = true
    #skip_get_ec2_platforms = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
    }
    time = {
      source  = "hashicorp/time"
    }
  }
}

data "aws_caller_identity" "current" {} # used for accesing Account ID and ARN

provider "aws" {
 default_tags {
   tags = {
     environment = "dev"
     project     = "aw-test"
   }
 }
}
