provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

module "vpc" {
  source = "git::git@github.com:cloudlovers/terraform-gcp-vpc.git"

  name                           = "vpc"
  environment                    = var.environment
  label_order                    = var.label_order
  google_compute_network_enabled = true
}

module "subnet" {
  source = "../"

  name        = "dev"
  environment = var.environment
  label_order = var.label_order

  google_compute_subnetwork_enabled  = true
  google_compute_firewall_enabled    = true
  google_compute_router_nat_enabled  = true
  module_enabled                     = true
  network                            = module.vpc.vpc_id
  project_id                         = "my_project_id"
  private_ip_google_access           = true
  allow                              = [{ "protocol" : "tcp", "ports" : ["22"] }]
  source_ranges                      = ["10.10.0.0/16"]
  asn                                = 64514
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  filter                             = "ERRORS_ONLY"
  dest_range                         = "0.0.0.0/0"
  next_hop_gateway                   = "default-internet-gateway"
  priority                           = 1000
  secondary_ip_ranges                = [{ "range_name" : "services", "ip_cidr_range" : "10.1.0.0/16" }, { "range_name" : "pods", "ip_cidr_range" : "10.3.0.0/16" }]
}