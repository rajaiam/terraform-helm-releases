terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0, != 2.6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY HELM CHART
# ---------------------------------------------------------------------------------------------------------------------

resource "helm_release" "application" {
  name             = var.application_name
  repository       = var.helm_repository
  chart            = var.helm_chart
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

 values = [
    yamlencode(
      var.helm_chart_values
    ),
  ]

  # Ensure both deployments and jobs wait for completion
  wait             = var.wait
  wait_for_jobs    = var.wait_for_jobs
  timeout          = var.timeout
  cleanup_on_fail  = var.cleanup_on_fail
  upgrade_install  = var.upgrade_install
}

# Optional wait for resource cleanup after destruction
resource "time_sleep" "wait_for_cleanup" {
  count = var.sleep_for_resource_culling ? 1 : 0

  depends_on = [helm_release.application]

  destroy_duration = var.cleanup_wait_duration
}