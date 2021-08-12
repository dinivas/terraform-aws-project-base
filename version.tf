terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.15"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "3.2.0-rc.0"
    }
  }
}
