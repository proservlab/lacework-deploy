output "athena_database_name" {
  value = local.athena_database_name
}

output cloudtrail_bucket_name {
  value = local.cloudtrail_bucket_name
}

output athena_results_bucket_name {
  value = local.athena_results_bucket_name
}

output athena_workgroup_name {
  value = local.athena_workgroup_name
}

output athena_create_table_named_query {
  value = local.athena_create_table_named_query
}

output athena_create_table_named_query_id {
  value = aws_athena_named_query.create_cloudtrail_table.id
}

output athena_drop_table_named_query {
  value = local.athena_drop_table_named_query
}

output athena_drop_table_named_query_id {
  value = aws_athena_named_query.drop_cloudtrail_table.id
}