output "id" {
  value       = module.subnet.*.id
  description = "an identifier for the resource with format."
}

output "self_link" {
  value = module.subnet.*.self_link
  description = "The URI of the created resource."
}

output "name" {
  value = module.subnet.*.name
  description = "The name of the resource, provided by the client when initially creating the resource."
}