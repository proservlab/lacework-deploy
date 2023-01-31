################################################## Environment Variables

Environment variables are stored here. They can be defined globally via variables.tfvars or per workspace via the variables-<WORKSPACE>.tfvars.

Examples of backend s3 usage are also included, such as using init.tfvars to create a new s3 bucket for terraform state storage and backend.tfvars to specify s3 configuration when applying changes.