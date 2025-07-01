module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "llm-cluster"
  cluster_version = "1.28"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    # On-demand node group (c6a.8xlarge)
    ollama_nodegroup = {
      name           = "ollama-nodegroup"
      instance_types = ["c6a.8xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 4
      desired_size   = 2

      labels = {
        nodegroup = "ollama"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/llm-cluster" = "owned"
      }
    }

    # Spot node group (mixed c6i.4xlarge and c6a.4xlarge)
    spot_nodegroup = {
      name           = "spot-nodegroup"
      instance_types = ["c6i.4xlarge", "c6a.4xlarge"]
      capacity_type  = "SPOT"
      min_size       = 2
      max_size       = 4
      desired_size   = 2

      labels = {
        nodegroup = "spot"
      }

      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]

      tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/llm-cluster" = "owned"
      }
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}