module "labels" {
  source      = "git::git@github.com:cloudlovers/terraform-google-labels.git"

  name        = var.name
  environment = var.environment
  label_order = var.label_order
}

resource "google_compute_subnetwork" "subnetwork" {
  count = var.google_compute_subnetwork_enabled && var.module_enabled ? 1 : 0

  name    = module.labels.id
  project = var.project_id
  network = var.network
  region  = var.gcp_region

  private_ip_google_access = var.private_ip_google_access
  ip_cidr_range            = cidrsubnet(var.ip_cidr_range, 0, 0)

  dynamic "secondary_ip_range" {
    for_each = var.secondary_ip_ranges

    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = var.log_config != null ? [var.log_config] : []

    content {
      aggregation_interval = try(log_config.value, "aggregation_interval", null)
      flow_sampling        = try(log_config.value, "flow_sampling", null)
      metadata             = try(log_config.value, "metadata", null)
      metadata_fields      = try(log_config.value, "metadata_fields", null)
      filter_expr          = try(log_config.value, "filter_expr", null)
    }
  }

  dynamic "timeouts" {
    for_each = try([var.module_timeouts.google_compute_subnetwork], [])

    content {
      create = try(timeouts.value.create, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }

}

resource "google_compute_firewall" "default" {
  count   = var.google_compute_firewall_enabled && var.module_enabled ? 1 : 0

  name    = format("%s-firewall", module.labels.name)
  network = var.network

  dynamic "allow" {
    for_each = var.allow

    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  source_ranges = var.source_ranges
}

resource "google_compute_route" "default" {
  count            = var.google_compute_route_enabled && var.module_enabled ? 1 : 0

  name             = format("%s-route", module.labels.name)
  dest_range       = var.dest_range
  network          = var.network
  next_hop_gateway = var.next_hop_gateway
  priority         = var.priority
}

resource "google_compute_router" "default" {
  count   = var.google_compute_route_enabled && var.module_enabled ? 1 : 0

  name    = format("%s-router", module.labels.name)
  network = var.network
  bgp {
    asn = var.asn
  }
}

resource "google_compute_address" "default" {
  count  = var.google_compute_address_enabled && var.module_enabled ? 1 : 0

  name   = format("%s-address", module.labels.name)
  region = var.gcp_region
}

resource "google_compute_router_nat" "nat" {
  count                              = var.google_compute_router_nat_enabled && var.module_enabled ? 1 : 0

  name                               = format("%s-router-nat", module.labels.name)
  router                             = join("", google_compute_router.default.*.name)
  region                             = var.gcp_region
  nat_ip_allocate_option             = var.nat_ip_allocate_option
  nat_ips                            = google_compute_address.default.*.self_link
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat

  log_config {
    enable = true
    filter = var.filter
  }
}
