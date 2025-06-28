terraform {
  backend "s3" {
    bucket = "my-tfstate-bucket"
    key    = "eks/gitops-lab/terraform.tfstate"
    region = "eu-west-2"
  }
}
