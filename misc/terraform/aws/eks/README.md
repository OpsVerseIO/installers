# EKS

Create an EKS cluster

If you don't have Terraform already installed on your system, you may [download from here](https://www.terraform.io/downloads)

## Steps

While in this directory...

1. Edit `vars.tfvars` to update the values based on your network/environment (make sure worker node subnets in `eks.tf` refer to only the private subnets)

2. Run `terraform init -var-file=vars.tfvars` 

3. Run `terraform plan -var-file=vars.tfvars` and review the plan

4. Run `terraform apply -var-file=vars.tfvars` to actually apply

