# Terraform Helm Releases Module

This Terraform module simplifies the deployment and management of Helm charts on Kubernetes clusters.

## Features

- Deploy multiple Helm charts with a single module
- Support for custom values files and inline values
- Namespace creation and management
- Configurable release settings (timeout, wait, atomic deployments)
- Support for private Helm repositories with authentication
- Dependency management between releases
- Easy rollback and upgrade capabilities

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Usage

### Basic Example

```hcl
module "helm_release" {
  source = "./terraform-helm-releases"

  releases = [
    {
      name             = "nginx-ingress"
      repository       = "https://kubernetes.github.io/ingress-nginx"
      chart            = "ingress-nginx"
      namespace        = "ingress-nginx"
      create_namespace = true
      version          = "4.8.0"
      values           = []
    }
  ]
}
```

### Advanced Example with Custom Values

```hcl
module "helm_releases" {
  source = "./terraform-helm-releases"

  releases = [
    {
      name             = "prometheus"
      repository       = "https://prometheus-community.github.io/helm-charts"
      chart            = "kube-prometheus-stack"
      namespace        = "monitoring"
      create_namespace = true
      version          = "51.0.0"
      
      values = [
        templatefile("${path.module}/values/prometheus-values.yaml", {
          storage_class = "gp3"
          retention     = "30d"
        })
      ]
      
      set = [
        {
          name  = "prometheus.prometheusSpec.retention"
          value = "30d"
        },
        {
          name  = "grafana.adminPassword"
          value = var.grafana_password
        }
      ]
      
      timeout       = 600
      wait          = true
      atomic        = true
      force_update  = false
      recreate_pods = false
    },
    {
      name             = "loki"
      repository       = "https://grafana.github.io/helm-charts"
      chart            = "loki-stack"
      namespace        = "monitoring"
      create_namespace = false
      version          = "2.9.11"
      
      depends_on_releases = ["prometheus"]
      
      values = [
        file("${path.module}/values/loki-values.yaml")
      ]
    }
  ]
}
```

### Multiple Releases with Dependencies

```hcl
module "app_stack" {
  source = "./terraform-helm-releases"

  releases = [
    {
      name             = "postgresql"
      repository       = "https://charts.bitnami.com/bitnami"
      chart            = "postgresql"
      namespace        = "database"
      create_namespace = true
      version          = "12.11.0"
      
      set_sensitive = [
        {
          name  = "auth.postgresPassword"
          value = var.db_password
        }
      ]
    },
    {
      name             = "redis"
      repository       = "https://charts.bitnami.com/bitnami"
      chart            = "redis"
      namespace        = "cache"
      create_namespace = true
      version          = "18.1.0"
    },
    {
      name             = "my-application"
      repository       = "https://my-helm-repo.example.com"
      chart            = "my-app"
      namespace        = "apps"
      create_namespace = true
      version          = "1.0.0"
      
      depends_on_releases = ["postgresql", "redis"]
      
      repository_username = var.repo_username
      repository_password = var.repo_password
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| releases | List of Helm releases to deploy | `list(object)` | `[]` | yes |

### Release Object Structure

Each release in the `releases` list supports the following attributes:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the Helm release | `string` | n/a | yes |
| repository | Helm chart repository URL | `string` | n/a | yes |
| chart | Name of the chart to deploy | `string` | n/a | yes |
| namespace | Kubernetes namespace for the release | `string` | `"default"` | no |
| create_namespace | Create namespace if it doesn't exist | `bool` | `false` | no |
| version | Chart version to deploy | `string` | Latest | no |
| values | List of values files (as strings) | `list(string)` | `[]` | no |
| set | List of value blocks with name/value pairs | `list(object)` | `[]` | no |
| set_sensitive | List of sensitive value blocks | `list(object)` | `[]` | no |
| timeout | Timeout for Helm operations (seconds) | `number` | `300` | no |
| wait | Wait until all resources are ready | `bool` | `true` | no |
| wait_for_jobs | Wait for jobs to complete | `bool` | `false` | no |
| atomic | Rollback on failure | `bool` | `true` | no |
| cleanup_on_fail | Delete resources on failed install | `bool` | `false` | no |
| force_update | Force resource updates | `bool` | `false` | no |
| recreate_pods | Recreate pods on upgrade | `bool` | `false` | no |
| max_history | Maximum number of release versions | `number` | `10` | no |
| skip_crds | Skip CRD installation | `bool` | `false` | no |
| verify | Enable chart verification | `bool` | `false` | no |
| dependency_update | Update chart dependencies | `bool` | `false` | no |
| disable_webhooks | Disable webhooks during operations | `bool` | `false` | no |
| repository_username | Username for private repository | `string` | `null` | no |
| repository_password | Password for private repository | `string` | `null` | no |
| depends_on_releases | List of release names this depends on | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| release_names | Map of deployed release names |
| release_namespaces | Map of release namespaces |
| release_versions | Map of deployed chart versions |
| release_statuses | Map of release statuses |
| release_metadata | Complete metadata for all releases |

## Examples

### Using External Values Files

Create a values file at `values/nginx-values.yaml`:

```yaml
controller:
  replicaCount: 3
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

Reference it in your Terraform:

```hcl
module "nginx" {
  source = "./terraform-helm-releases"

  releases = [
    {
      name             = "nginx"
      repository       = "https://kubernetes.github.io/ingress-nginx"
      chart            = "ingress-nginx"
      namespace        = "ingress"
      create_namespace = true
      values = [
        file("${path.module}/values/nginx-values.yaml")
      ]
    }
  ]
}
```

### Using Templated Values

```hcl
module "app" {
  source = "./terraform-helm-releases"

  releases = [
    {
      name             = "my-app"
      repository       = "https://charts.example.com"
      chart            = "application"
      namespace        = "production"
      create_namespace = true
      
      values = [
        templatefile("${path.module}/values/app-values.yaml.tpl", {
          environment      = "production"
          replicas        = 5
          domain          = "app.example.com"
          database_host   = module.database.endpoint
          cache_endpoint  = module.redis.endpoint
        })
      ]
    }
  ]
}
```

## Best Practices

1. **Version Pinning**: Always specify chart versions to ensure reproducible deployments
2. **Namespace Management**: Use `create_namespace = true` for better resource organization
3. **Atomic Deployments**: Enable `atomic = true` for automatic rollback on failures
4. **Dependency Ordering**: Use `depends_on_releases` to ensure correct deployment order
5. **Sensitive Values**: Use `set_sensitive` for passwords and secrets
6. **Resource Limits**: Define appropriate timeouts based on chart complexity
7. **Values Organization**: Keep values files in a dedicated directory structure

## Troubleshooting

### Release Failed to Install

- Check the timeout value is sufficient for chart complexity
- Verify namespace exists or `create_namespace` is enabled
- Review Helm chart requirements and dependencies
- Check Kubernetes cluster resources and permissions

### Values Not Applied

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

## License

MIT License - See LICENSE file for details

## Authors

Created and maintained by your DevOps team.

## Resources

- [Terraform Helm Provider Documentation](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
