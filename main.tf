provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_blueprints.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_blueprints.eks_cluster_id
}


data "aws_availability_zones" "available" {}

locals {
  name   = "eks-argocd"
  region = "us-east-2"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

#---------------------------------------------------------------
# EKS Blueprints
#---------------------------------------------------------------

module "eks_blueprints" {
  source = "./modules/"

  cluster_name    = local.name
  cluster_version = "1.22"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    md_amd = {
      node_group_name = "managed-ondemand-amd"
      instance_types  = [var.amdnodetype]
      min_size        = var.amdnodemin
      desired_size    = var.amdnodedesired
      subnet_ids      = module.vpc.private_subnets
    }
    md_arm = {
      node_group_name = "managed-ondemand-arm"
      instance_types  = [var.armnodetype]
      min_size        = var.armnodemin
      desired_size    = var.armnodedesired
      subnet_ids      = module.vpc.private_subnets
      ami_type        = "AL2_ARM_64"  
    }
  }

  tags = local.tags
}

module "eks_blueprints_kubernetes_addons" {
  source = "./modules/modules/kubernetes-addons"
  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version
  enable_argocd = true
  argocd_helm_config = {
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt(data.aws_secretsmanager_secret_version.admin_password_version.secret_string)
      }
    ]
  }
  argocd_manage_add_ons = true 
  argocd_applications = {
    addons = {
      path               = "chart"
      repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
      add_on_application = true
    }
    workloads = {
      path               = "envs/dev"
      repo_url           = "https://github.com/aws-samples/eks-blueprints-workloads.git"
      add_on_application = false
    }
  }
  enable_amazon_eks_coredns    = true
  enable_amazon_eks_kube_proxy = true
  enable_cert_manager       = true
  enable_cluster_autoscaler = true
  enable_metrics_server     = var.metrics_server
  enable_prometheus         = var.prometheus
  enable_traefik            = var.traefik
  enable_argo_rollouts      = var.argo_rollouts
  enable_vault = var.vault
  enable_aws_load_balancer_controller = true
  tags = local.tags
}

#Application Deployment using helm

resource "kubernetes_namespace" "hashicrop_namespace" {
  metadata {
    name = "hashicorp"
  }
}

resource "helm_release" "hashicrop_vault" {
  name       = "hashicropvault"
  namespace  = "hashicorp"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  timeout = 600
  depends_on = [kubernetes_namespace.hashicrop_namespace]
}

#Using traefik as ingress for team-riker app

resource "kubernetes_ingress_v1" "traefik_ingress" {
  metadata {
    name = "riker-traefik-ingress"
    namespace = "team-riker"
  }
  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = "guestbook-ui"
              port {
                number = 80
              }
            }
          }
          path = "/"
        }
      }
    }
  }
}

#---------------------------------------------------------------
# ArgoCD Admin Password credentials with Secrets Manager
# Login to AWS Secrets manager with the same role as Terraform to extract the ArgoCD admin password with the secret name as "argocd"
#---------------------------------------------------------------
resource "random_password" "argocd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "arogcd" {
  name                    = "argocd"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "arogcd" {
  secret_id     = aws_secretsmanager_secret.arogcd.id
  secret_string = random_password.argocd.result
}

data "aws_secretsmanager_secret_version" "admin_password_version" {
  secret_id = aws_secretsmanager_secret.arogcd.id

  depends_on = [aws_secretsmanager_secret_version.arogcd]
}


#---------------------------------------------------------------
# Supporting Resources
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = local.tags
}
