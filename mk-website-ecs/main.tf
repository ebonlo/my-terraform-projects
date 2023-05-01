# configure aws provider
provider "aws" {
    region = var.region
  
}

# create vpc
module "vpc" {
    source = "../modules/vpc"
    region = var.region
    project_name = var.project_name
    vpc_cidr = var.vpc_cidr    
    public1_subnet_cidr = var.public1_subnet_cidr
    public2_subnet_cidr = var.public2_subnet_cidr
    app1_subnet_cidr = var.app1_subnet_cidr
    app2_subnet_cidr = var.app2_subnet_cidr
    data1_subnet_cidr = var.data1_subnet_cidr
    data2_subnet_cidr = var.data2_subnet_cidr

  
}