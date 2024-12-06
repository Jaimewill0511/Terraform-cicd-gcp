provider "google" {
  project = var.project_id
  region  = var.region
  zone = var.zone
}

resource "google_compute_instance" "ci_cd_instance" {
  name         = "ci-cd-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {
      # Ephemeral external IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
  EOF
}

# Create a Cloud SQL instance
resource "google_sql_database_instance" "main" {
  name             = "postgres-instance"
  database_version = "POSTGRES_14" 
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro" # Choose a machine type (adjust as needed)

    ip_configuration {
      ipv4_enabled    = true
      authorized_networks {
        name  = "allow-localhost"
        value = "0.0.0.0/0" 
      }
    }
  }
}

# Create a database
resource "google_sql_database" "myappdb" {
  name     = "myappdb"
  instance = google_sql_database_instance.main.name
}

# Cloud SQL database
resource "google_sql_database" "default_db" {
  name     = "assignment-02-database"
  instance = google_sql_database_instance.main.name
}

# Create a user
resource "google_sql_user" "myuser" {
  name     = "myuser"
  instance = google_sql_database_instance.main.name
  password = "mypassword"
}

resource "google_sql_user" "postgres" {
  name     = "postgres"
  instance = google_sql_database_instance.main.name
  password = "mypassword"
}


# Script to run SQL commands for granting privileges and schema access
# resource "null_resource" "initialize_db" {
#   depends_on = [
#     google_sql_user.myuser,
#     google_sql_database.myappdb
#   ]

#   provisioner "local-exec" {
#     command = <<EOT
#       PGPASSWORD="mypassword" psql -h ${google_sql_database_instance.main.public_ip_address} -U postgres -d myappdb -c "GRANT ALL PRIVILEGES ON DATABASE myappdb TO myuser;" -c "\\c myappdb;" -c "GRANT USAGE ON SCHEMA public TO myuser;" -c "GRANT ALL PRIVILEGES ON SCHEMA public TO myuser;"
#     EOT
#   }
# }




resource "google_container_cluster" "fusion-gke" {
  name                     = var.gke_cluster_name
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection = false

  network    = "default" # Replace with your VPC network name if not using default
  subnetwork = "default" # Replace with your subnet name if not using default

  
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }


  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }

    
  }

  # secret_manager_config {
  #     enabled = true # Enable Secret Manager integration
  #   }

   
}

resource "google_container_node_pool" "fusion-gke-node-pool" {
  name       = "${var.gke_cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.fusion-gke.name
  node_count = 1
  



  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "e2-medium" # You can adjust this based on your needs
    disk_size_gb = 100
    disk_type    = "pd-standard"

    image_type = "COS_CONTAINERD"

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
