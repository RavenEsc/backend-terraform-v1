terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  cloud {
    organization = "raven-for-aws"

    workspaces {
      name = "raven-spen-blog-site"
    }
  }
}
