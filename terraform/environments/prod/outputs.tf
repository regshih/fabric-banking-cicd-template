output "resource_group_name" {
  value = module.capacity.resource_group_name
}

output "capacity_name" {
  value = module.capacity.capacity_name
}

output "workspace_id" {
  value = module.workspace.workspace_id
}

output "deployment_pipeline_id" {
  value = module.deployment_pipeline.deployment_pipeline_id
}

output "deployment_pipeline_stages" {
  value = module.deployment_pipeline.stages
}
