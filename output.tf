output "database_connection_info" {
  description = "Connection details for the PostgreSQL database instance"
  sensitive = true
  value = {
    instance_connection_name = google_sql_database_instance.main.connection_name
    db_user                  = google_sql_user.db_user.name
    db_ip_address            = google_sql_database_instance.main.public_ip_address
    db_password              = google_sql_user.db_user.password
    database_name            = google_sql_database.myappdb.name
  }
}

output "kubernetes_version" {
  description = "Kubernetes version of the GKE cluster"
  value       = google_container_cluster.fusion-gke.master_version
}

output "network_name" {
  description = "Name of the VPC network used by the GKE cluster"
  value       = google_container_cluster.fusion-gke.network
}
