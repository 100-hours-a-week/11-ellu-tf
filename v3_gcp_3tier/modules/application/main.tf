resource "google_compute_instance_template" "app_template" {
  name_prefix  = "${var.prefix}-app-template-"
  machine_type = var.machine_type
  project      = var.project_id
  tags         = ["ssh", "http-server", "https-server"]

  disk {
    source_image = var.disk_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size
    disk_type    = "pd-ssd"
  }

  network_interface {
    subnetwork = var.subnet_self_link
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "app_group" {
  name               = "${var.prefix}-app-group"
  base_instance_name = "${var.prefix}-app"
  region             = var.region
  project            = var.project_id
  
  distribution_policy_zones = var.zones
  distribution_policy_target_shape = "BALANCED" 

  target_size        = 1  

  version {
    instance_template = google_compute_instance_template.app_template.id
  }

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    max_unavailable_fixed          = 2
    max_surge_fixed                = 2
    replacement_method             = "SUBSTITUTE"
    instance_redistribution_type   = "NONE"
  }
  
  depends_on = [google_compute_instance_template.app_template]
  
}