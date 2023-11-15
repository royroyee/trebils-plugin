module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  azs  = var.azs
  cidr = var.vpc_cidr

  # Create NAT Gateway
  enable_nat_gateway = true

  # Create Nat Gateway only one
  single_nat_gateway = true

  public_subnets = [for index in range(2):
    cidrsubnet(var.vpc_cidr, 4, index)]

  private_subnets = [for index in range(2):
    cidrsubnet(var.vpc_cidr, 4, index + 2)]
}