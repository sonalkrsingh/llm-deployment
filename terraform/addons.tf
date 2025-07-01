module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # EKS Add-ons
  eks_addons = {
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Add-ons
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  enable_external_dns                 = true

  # For FluentBit, we'll use a separate Helm release since it's not directly supported
  # in the current version of the EKS Blueprints Addons module

  tags = {
    Environment = "dev"
  }
}

# Separate Helm release for FluentBit
resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.37.0"
  namespace  = "amazon-cloudwatch"

  values = [templatefile("${path.module}/fluentbit-values.yaml", {
    aws_region   = "ap-south-1"
    cluster_name = module.eks.cluster_name
  })]

  depends_on = [module.eks_blueprints_addons]
}

resource "aws_iam_policy" "fluentbit_cloudwatch" {
  name        = "FluentBitCloudWatch-${module.eks.cluster_name}"
  description = "Policy for FluentBit to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}