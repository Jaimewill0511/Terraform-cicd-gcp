variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud region to deploy resources in"
  type        = string
  default     = "us-central1"
}


variable "zone" {
  description = "The Google Cloud region to deploy resources in"
  type        = string
  default     = "us-central1"
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "terraform-gke"

}

