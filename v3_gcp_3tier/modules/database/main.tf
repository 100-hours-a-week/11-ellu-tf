resource "google_compute_resource_policy" "backup_schedule" {
  name    = "${var.prefix}-db-snapshot-schedule"
  project = var.project_id
  region  = var.region
  
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "01:00" 
      }
    }
    
    retention_policy {
      max_retention_days    = 7 
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    
    snapshot_properties {
      storage_locations = [var.region]
      guest_flush       = true
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "attachment" {
  name     = google_compute_resource_policy.backup_schedule.name
  disk     = google_compute_disk.db_data_disk.name
  zone     = var.zone
  project  = var.project_id
  
  depends_on = [
    google_compute_resource_policy.backup_schedule,
    google_compute_disk.db_data_disk
  ]
}
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_storage_bucket" "db_backup_bucket" {
  name          = var.backup_bucket
  location      = var.region
  project       = var.project_id
  force_destroy = false
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30 
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_compute_address" "db_internal_ip" {
  name         = "${var.prefix}-db-internal-ip"
  subnetwork   = var.subnet_self_link
  address_type = "INTERNAL"
  region       = var.region
  project      = var.project_id
}

resource "google_compute_disk" "db_data_disk" {
  name    = "${var.prefix}-db-data-disk"
  type    = "pd-ssd"
  zone    = var.zone
  size    = var.disk_size
  project = var.project_id
}

resource "google_compute_instance" "db_server" {
  name         = "${var.prefix}-db-server"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = ["ssh", "database"]

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = 50 
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.db_data_disk.self_link
    device_name = "data-disk"
  }

  network_interface {
    subnetwork = var.subnet_self_link
    network_ip = google_compute_address.db_internal_ip.address
    
  }

  metadata = {
    startup-script = templatefile("${path.module}/startup_script.tpl", {
      backup_bucket = var.backup_bucket
      backup_schedule = var.backup_schedule
      data_disk_device = "/dev/disk/by-id/google-data-disk"
      data_mount_point = "/data"
    })
  }

  service_account {
    email  = var.db_service_account
    scopes = ["cloud-platform"]
  }

  deletion_protection = false 

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }

  depends_on = [
    google_compute_disk.db_data_disk,
    google_compute_address.db_internal_ip,
    google_storage_bucket.db_backup_bucket
  ]
}