output "application_name" {
  description = "The name of the deployed application"
  value       = helm_release.application.name
}

output "helm_chart_name" {
  description = "The name of the deployed Helm chart"
  value       = helm_release.application.chart
}

output "helm_chart_version" {
  description = "The version of the deployed Helm chart"
  value       = helm_release.application.version
}

output "namespace" {
  description = "The namespace where the application is deployed"
  value       = helm_release.application.namespace
}

output "status" {
  description = "The status of the Helm release"
  value       = helm_release.application.status
}
