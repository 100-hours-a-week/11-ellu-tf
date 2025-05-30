resource "google_compute_health_check" "http_health_check" {
  name               = "${var.prefix}-http-health-check"
  project            = var.project_id
  timeout_sec        = 5
  check_interval_sec = 10
  
  http_health_check {
    port         = 80
    request_path = "/" 
  }
}

resource "google_compute_global_address" "lb_ip" {
  name         = "${var.prefix}-lb-ip"
  project      = var.project_id
  address_type = "EXTERNAL"
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  count = var.ssl_certificate == "" ? 1 : 0
  
  name     = "${var.prefix}-ssl-cert"
  project  = var.project_id
  
  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "${var.prefix}-backend-service"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.http_health_check.id]
  load_balancing_scheme = "EXTERNAL"
  
  backend {
    group           = var.backend_instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  
  log_config {
    enable      = true
    sample_rate = 1.0
  }
  
  depends_on = [google_compute_health_check.http_health_check]
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.prefix}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.backend_service.id
  
  depends_on = [google_compute_backend_service.backend_service]
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name     = "${var.prefix}-http-proxy"
  project  = var.project_id
  url_map  = google_compute_url_map.url_map.id
  
  depends_on = [google_compute_url_map.url_map]
}


resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "${var.prefix}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = var.ssl_certificate != "" ? [var.ssl_certificate] : [google_compute_managed_ssl_certificate.ssl_cert[0].id]
  
  depends_on = [
    google_compute_url_map.url_map,
    google_compute_managed_ssl_certificate.ssl_cert
  ]
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "${var.prefix}-http-forwarding-rule"
  project               = var.project_id
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  load_balancing_scheme = "EXTERNAL"
  
  depends_on = [
    google_compute_global_address.lb_ip,
    google_compute_target_http_proxy.http_proxy
  ]
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = "${var.prefix}-https-forwarding-rule"
  project               = var.project_id
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  load_balancing_scheme = "EXTERNAL"
  
  depends_on = [
    google_compute_global_address.lb_ip,
    google_compute_target_https_proxy.https_proxy
  ]
}

resource "google_dns_record_set" "dns_record" {
  count        = var.create_dns_record ? 1 : 0
  name         = "${var.domain_name}."
  project      = var.project_id
  managed_zone = var.dns_managed_zone
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.lb_ip.address]
  
  depends_on = [google_compute_global_address.lb_ip]
}