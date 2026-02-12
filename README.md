# Terraform Helm Release Module

This Terraform module simplifies the deployment and management of Helm charts on Kubernetes clusters.

## Features

- Deploy Helm charts with customizable values
- Namespace creation and management
- Configurable release settings (timeout, wait, cleanup)
- Support for upgrade-install mode
- Optional resource cleanup wait time after destruction
- YAML-encoded values support

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 4.0 |
| helm | ~> 2.0, != 2.6.0 |
| time | ~> 0.7 |

## Providers

| Name | Version |
|------|---------|
| helm | ~> 2.0, != 2.6.0 |
| time | ~> 0.7 |
| aws | ~> 4.0 |

## Usage

### Basic Example

```hcl
module "nginx_ingress" {
  source = "./modules/helm"

  application_name   = "nginx-ingress"
  namespace          = "ingress-nginx"
  create_namespace   = true
  
  helm_repository    = "https://kubernetes.github.io/ingress-nginx"
  helm_chart         = "ingress-nginx"
  helm_chart_version = "4.8.0"
  
  helm_chart_values = {}
}
```

### Example with Custom Values

```hcl
module "prometheus" {
  source = "./modules/helm"

  application_name   = "prometheus"
  namespace          = "monitoring"
  create_namespace   = true
  
  helm_repository    = "https://prometheus-community.github.io/helm-charts"
  helm_chart         = "kube-prometheus-stack"
  helm_chart_version = "51.0.0"
  
  helm_chart_values = {
    prometheus = {
      prometheusSpec = {
        retention            = "30d"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp3"
              accessModes     = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "50Gi"
                }
              }
            }
          }
        }
      }
    }
    grafana = {
      enabled       = true
      adminPassword = "changeme"
      persistence = {
        enabled = true
        size    = "10Gi"
      }
    }
  }
}
```

### Example with Advanced Configuration

```hcl
module "application" {
  source = "./modules/helm"

  application_name   = "my-app"
  namespace          = "production"
  create_namespace   = true
  
  helm_repository    = "https://charts.example.com"
  helm_chart         = "my-application"
  helm_chart_version = "1.2.3"
  
  helm_chart_values = {
    replicaCount = 3
    
    image = {
      repository = "myregistry.azurecr.io/my-app"
      tag        = "v1.2.3"
      pullPolicy = "IfNotPresent"
    }
    
    service = {
      type = "ClusterIP"
      port = 80
    }
    
    ingress = {
      enabled = true
      hosts = [
        {
          host = "app.example.com"
          paths = [
            {
              path     = "/"
              pathType = "Prefix"
            }
          ]
        }
      ]
    }
    
    resources = {
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
    }
  }
  
  wait             = true
  wait_for_jobs    = true
  timeout          = 600
  cleanup_on_fail  = true
  upgrade_install  = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| application_name | The name of the application. Used for labeling Kubernetes resources | `string` | n/a | yes |
| namespace | The Kubernetes Namespace to deploy the helm chart | `string` | n/a | yes |
| create_namespace | Whether to create the Kubernetes Namespace if it does not exist | `bool` | `false` | no |
| helm_repository | The URL of the Helm chart repository | `string` | n/a | yes |
| helm_chart | The name of the Helm chart to deploy | `string` | n/a | yes |
| helm_chart_version | The version of the Helm chart to deploy | `string` | n/a | yes |
| helm_chart_values | A map of values to pass to the Helm chart | `map(any)` | `{}` | no |
| wait | Wait until all resources are ready | `bool` | varies | no |
| wait_for_jobs | Wait for jobs to complete | `bool` | varies | no |
| timeout | Timeout for Helm operations (seconds) | `number` | varies | no |
| cleanup_on_fail | Delete resources on failed install | `bool` | varies | no |
| upgrade_install | Enable upgrade-install mode | `bool` | varies | no |
| sleep_for_resource_culling | Enable wait time after resource destruction | `bool` | varies | no |
| cleanup_wait_duration | Duration to wait for resource cleanup after destruction | `string` | varies | no |

## Outputs

| Name | Description |
|------|-------------|
| application_name | The name of the deployed application |
| helm_chart_name | The name of the deployed Helm chart |
| helm_chart_version | The version of the deployed Helm chart |
| namespace | The namespace where the application is deployed |
| status | The status of the Helm release |

### Using Outputs

You can reference module outputs in your Terraform configuration:

```hcl
module "my_app" {
  source = "./modules/helm"

  application_name   = "my-application"
  namespace          = "production"
  create_namespace   = true
  
  helm_repository    = "https://charts.example.com"
  helm_chart         = "my-app"
  helm_chart_version = "1.0.0"
  
  helm_chart_values = {}
}

# Use the module outputs
output "deployed_app_name" {
  value = module.my_app.application_name
}

output "deployed_chart_version" {
  value = module.my_app.helm_chart_version
}

output "deployment_namespace" {
  value = module.my_app.namespace
}

output "release_status" {
  value = module.my_app.status
}
```

## Troubleshooting

### Release Failed to Install

- Ensure `create_namespace = true` if the namespace doesn't exist
- Verify the Helm chart repository URL is accessible
- Check the chart name and version are correct
- Review Kubernetes cluster connection and permissions
- Increase `timeout` value for complex charts

### Values Not Applied Correctly

- Verify the structure of `helm_chart_values` matches the chart's expected values
- Check for YAML/HCL syntax errors in the values map
- Review the chart's documentation for correct value keys
- The module uses `yamlencode()` to convert the map to YAML format

### Provider Configuration Issues

- Ensure Helm provider is properly configured with Kubernetes access
- Verify AWS provider is configured if using EKS
- Check that the Kubernetes cluster is accessible from where Terraform ru
    replicaCount = local.environment == "production" ? 3 : 1
    
    resources = {
      limits = {
        cpu    = local.environment == "production" ? "1000m" : "500m"
        memory = local.environment == "production" ? "1Gi" : "512Mi"
      }
      requests = {
        cpu    = local.environment == "production" ? "500m" : "250m"
        memory = local.environment == "production" ? "512Mi" : "256Mi"
      }
    }
  }
}

module "application" {
  source = "./modules/helm"

  application_name   = "my-app"
  namespace          = local.environment
  create_namespace   = true
  
  helm_repository    = "https://charts.example.com"
  helm_chart         = "my-app"
  helm_chart_version = "2.0.0"
  
  helm_chart_values = local.app_config
- Ensure values file paths are correct
- Verify YAML syntax in values files
- Check that templated variables are properly defined
- Use `set` blocks for simple overrides

### Authentication Issues

- Verify `repository_username` and `repository_password` for private repos
- Check repository URL is accessible
- Ensure credentials have necessary permissions

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.

## Authors

Created and maintained by your DevOps team.

## Resources

- [Terraform Helm Provider Documentation](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Notes

- The `helm_chart_values` variable accepts a map that gets automatically converted to YAML using `yamlencode()`
- Additional configuration variables (`wait`, `wait_for_jobs`, `timeout`, etc.) may need to be added to [variables.tf](modules/helm/variables.tf) if you want to customize these behaviors
- Module outputs provide access to deployment metadata including application name, chart version, namespace, and release status
