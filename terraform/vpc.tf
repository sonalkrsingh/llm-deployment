module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "llm-cluster-vpc"
  cidr = "172.31.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20"]
  public_subnets  = ["172.31.48.0/20", "172.31.64.0/20", "172.31.80.0/20"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}