locals {
  namespace = "crossplane-system"

  default_helm_config = {
    name        = "crossplane"
    chart       = "crossplane"
    repository  = "https://charts.crossplane.io/stable/"
    version     = "1.8.1"
    namespace   = local.namespace
    description = "Crossplane Helm chart"
    values      = local.default_helm_values
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )

  default_helm_values = [templatefile("${path.module}/values.yaml", {
    operating-system = "linux"
  })]

  aws_provider_sa        = "aws-provider"
  jet_aws_provider_sa    = "jet-aws-provider"
  aws_current_account_id = var.account_id
  aws_current_partition  = var.aws_partition
}
