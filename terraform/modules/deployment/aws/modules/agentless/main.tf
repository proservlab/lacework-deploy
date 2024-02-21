

module "lacework_aws_agentless_scanning_global" {
  source  = "lacework/agentless-scanning/aws"
  version = "~> 0.13"

  # fixed override input here
  global                    = true
  lacework_integration_name = "sidekick_from_terraform"
  
  snapshot_role = var.snapshot_role
  global_module_reference = var.global_module_reference
  image_url = var.image_url
  scan_frequency_hours = var.scan_frequency_hours
  filter_query_text = var.filter_query_text
  scan_containers = var.scan_containers
  scan_host_vulnerabilities = var.scan_host_vulnerabilities
  scan_multi_volume = var.scan_multi_volume
  scan_stopped_instances = var.scan_stopped_instances
  bucket_force_destroy = var.bucket_force_destroy
  bucket_encryption_enabled = var.bucket_encryption_enabled
  bucket_sse_algorithm = var.bucket_sse_algorithm
  bucket_sse_key_arn = var.bucket_sse_key_arn
  # bucket_tags = var.bucket_tags
  lacework_account = var.lacework_account
  lacework_domain = var.lacework_domain
  lacework_aws_account_id = var.lacework_aws_account_id
  iam_service_linked_role = var.iam_service_linked_role
  secretsmanager_kms_key_id = var.secretsmanager_kms_key_id
  vpc_id = var.vpc_id
  vpc_cidr_block = var.vpc_cidr_block
  use_existing_vpc = var.use_existing_vpc
  use_existing_security_group = var.use_existing_security_group
  security_group_id = var.security_group_id
  use_existing_subnet = var.use_existing_subnet
  subnet_id = var.subnet_id
  org_account_mappings = var.org_account_mappings
  organization = var.organization
  agentless_scan_ecs_task_role_arn = var.agentless_scan_ecs_task_role_arn
  agentless_scan_ecs_execution_role_arn = var.agentless_scan_ecs_execution_role_arn
  agentless_scan_ecs_event_role_arn = var.agentless_scan_ecs_event_role_arn
  agentless_scan_secret_arn = var.agentless_scan_secret_arn
  prefix = var.prefix
  suffix = var.suffix
  use_existing_cross_account_role = var.use_existing_cross_account_role
  use_existing_task_role = var.use_existing_task_role
  use_existing_execution_role = var.use_existing_execution_role
  use_existing_event_role = var.use_existing_event_role
  cross_account_role_arn = var.cross_account_role_arn
  cross_account_role_name = var.cross_account_role_name
  external_id = var.external_id
  additional_environment_variables = var.additional_environment_variables
  use_internet_gateway = var.use_internet_gateway
}

// Create regional resources in our first region
module "lacework_aws_agentless_scanning_region" {
  source  = "lacework/agentless-scanning/aws"
  version = "~> 0.13"

  regional                              = true
  agentless_scan_ecs_task_role_arn      = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_task_role_arn
  agentless_scan_ecs_execution_role_arn = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_execution_role_arn
  agentless_scan_ecs_event_role_arn     = module.lacework_aws_agentless_scanning_global.agentless_scan_ecs_event_role_arn
  agentless_scan_secret_arn             = module.lacework_aws_agentless_scanning_global.agentless_scan_secret_arn
  lacework_account                      = module.lacework_aws_agentless_scanning_global.lacework_account
  prefix                                = module.lacework_aws_agentless_scanning_global.prefix
  suffix                                = module.lacework_aws_agentless_scanning_global.suffix

  snapshot_role = var.snapshot_role
  global_module_reference = var.global_module_reference
  image_url = var.image_url
  scan_frequency_hours = var.scan_frequency_hours
  filter_query_text = var.filter_query_text
  scan_containers = var.scan_containers
  scan_host_vulnerabilities = var.scan_host_vulnerabilities
  scan_multi_volume = var.scan_multi_volume
  scan_stopped_instances = var.scan_stopped_instances
  bucket_force_destroy = var.bucket_force_destroy
  bucket_encryption_enabled = var.bucket_encryption_enabled
  bucket_sse_algorithm = var.bucket_sse_algorithm
  bucket_sse_key_arn = var.bucket_sse_key_arn
  # bucket_tags = var.bucket_tags
  lacework_domain = var.lacework_domain
  lacework_aws_account_id = var.lacework_aws_account_id
  iam_service_linked_role = var.iam_service_linked_role
  secretsmanager_kms_key_id = var.secretsmanager_kms_key_id
  vpc_id = var.vpc_id
  vpc_cidr_block = var.vpc_cidr_block
  use_existing_vpc = var.use_existing_vpc
  use_existing_security_group = var.use_existing_security_group
  security_group_id = var.security_group_id
  use_existing_subnet = var.use_existing_subnet
  subnet_id = var.subnet_id
  org_account_mappings = var.org_account_mappings
  organization = var.organization
  use_existing_cross_account_role = var.use_existing_cross_account_role
  use_existing_task_role = var.use_existing_task_role
  use_existing_execution_role = var.use_existing_execution_role
  use_existing_event_role = var.use_existing_event_role
  cross_account_role_arn = var.cross_account_role_arn
  cross_account_role_name = var.cross_account_role_name
  external_id = var.external_id
  additional_environment_variables = var.additional_environment_variables
  use_internet_gateway = var.use_internet_gateway
}