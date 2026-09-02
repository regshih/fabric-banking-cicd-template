output "deployment_pipeline_id" {
  description = "Fabric deployment pipeline ID."
  value       = fabric_deployment_pipeline.this.id
}

output "stages" {
  description = "Fabric deployment pipeline stages, including generated IDs."
  value       = fabric_deployment_pipeline.this.stages
}
