# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket = "my-terraform-states-bucket"
    key = "mk-website-ecs.tfstate"
    region = "us-east-1"
    
  }
}