variable "application_name" {
  description = "The name of the application. Used for labeling Kubernetes resources."
  type        = string
}

variable "namespace" {
  description = "The Kubernetes Namespace to deploy the helm chart."
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes Namespace if it does not exist."
  type        = bool
  default     = false
}

variable "helm_repository" {
  description = "The URL of the Helm chart repository."
  type        = string
}

variable "helm_chart" {
  description = "The name of the Helm chart to deploy."
  type        = string
}

variable "helm_chart_version" {
  description = "The version of the Helm chart to deploy."
  type        = string
}

variable "helm_chart_values" {
  description = "A map of values to pass to the Helm chart."
  type        = map(any)
  default     = {}
}
