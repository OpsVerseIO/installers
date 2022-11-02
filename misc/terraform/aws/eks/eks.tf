# Creates a 3-node EKS cluster. You may additionally want to:
#   - add more subnets to span whichever networks you want
#   - add manage_aws_auth="true" in case you do auth maps here too 
#   - change cluster/module name to one that fits your org conventions

module "opsverse-eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0"

  cluster_name    = "opsverse-eks-cluster"
  cluster_version = "1.21"
  # manage_aws_auth= "true"

  // Need at least 2 AZs for EKS to create cluster
  subnets         = [
                    "${var.subnet_ids[0]}",
                    "${var.subnet_ids[1]}",
                    "${var.subnet_ids[2]}",
                    "${var.subnet_ids[3]}"
                    ]
  vpc_id          = "${var.vpc_id}"
  enable_irsa     = "true" 

  worker_groups = [
    {
      instance_type = "m5a.xlarge"
      asg_max_size = 3
      asg_desired_capacity = 3
      asg_min_size = 3
      root_volume_size = "30"
      root_volume_type = "gp2"
      key_name = var.keypair_name
      subnets = [
        "${var.subnet_ids[0]}",
        "${var.subnet_ids[2]}"
      ]
    }
  ]
}
