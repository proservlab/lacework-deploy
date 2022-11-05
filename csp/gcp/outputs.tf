output "gcp_organization_id" {
  value = data.google_organization.org.org_id
}

output "gcp_projects" {
  value = data.google_projects.projects
}