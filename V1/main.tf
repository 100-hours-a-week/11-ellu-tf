provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

resource "google_compute_network" "vpc" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "subnet" {
  name          = "${var.prefix}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.prefix}-allow-http-https"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.prefix}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}


resource "google_service_account" "app_service_account" {
  account_id   = "${var.prefix}-sa"
  display_name = "Application Service Account"
  project      = var.project_id
}


resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

resource "google_compute_address" "static_ip" {
  name    = "${var.prefix}-static-ip"
  region  = var.region
  project = var.project_id
}

resource "google_compute_instance" "app_server" {
  name         = "${var.prefix}-server"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = ["ssh", "http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup_script.tpl", {

  })

  service_account {
    email  = google_service_account.app_service_account.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [google_compute_address.static_ip]
}


resource "google_dns_record_set" "dns_record" {
  count        = var.create_dns_record ? 1 : 0
  name         = "${var.domain_name}."
  managed_zone = var.dns_managed_zone
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_instance.app_server.network_interface[0].access_config[0].nat_ip]
}
