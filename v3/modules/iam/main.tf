resource "google_service_account" "app_service_account" {
  account_id   = "${var.prefix}-app-sa"
  display_name = "Application Service Account"
  project      = var.project_id
}

resource "google_service_account" "db_service_account" {
  account_id   = "${var.prefix}-db-sa"
  display_name = "Database Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "app_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

resource "google_project_iam_member" "app_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

resource "google_project_iam_member" "app_metrics_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

resource "google_project_iam_member" "db_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.db_service_account.email}"
}

resource "google_project_iam_member" "db_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.db_service_account.email}"
}

resource "google_project_iam_member" "db_metrics_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.db_service_account.email}"
}

resource "google_project_iam_member" "db_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.db_service_account.email}"
}