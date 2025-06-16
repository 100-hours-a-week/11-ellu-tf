resource "google_compute_address" "app_internal_ip" {
  count        = length(var.zones)
  name         = "${var.prefix}-app-internal-ip-${count.index + 1}"
  subnetwork   = var.subnet_self_link
  address_type = "INTERNAL"
  region       = var.region
  project      = var.project_id
}

resource "google_compute_instance" "app_server" {
  count        = length(var.zones)
  name         = "${var.prefix}-app-server-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zones[count.index]
  project      = var.project_id
  tags         = ["ssh", "http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
    network_ip = google_compute_address.app_internal_ip[count.index].address
  }

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  scheduling {
    on_host_maintenance = "TERMINATE" 
    automatic_restart   = true
  }

  metadata = {
    startup-script = templatefile("${path.module}/startup_script.tpl", {
      db_private_ip = var.db_private_ip
    })
  }

  service_account {
    email  = var.app_service_account
    scopes = ["cloud-platform"]
  }

  deletion_protection = false

  depends_on = [google_compute_address.app_internal_ip]
}

resource "google_compute_instance_group" "app_group" {
  name        = "${var.prefix}-app-group"
  description = "Unmanaged instance group for app servers"
  zone        = var.zones[0] 
  project     = var.project_id
  
  instances = [for instance in google_compute_instance.app_server : instance.self_link]

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }

  depends_on = [google_compute_instance.app_server]
}