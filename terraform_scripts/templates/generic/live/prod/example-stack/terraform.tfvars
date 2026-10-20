region            = "eu-west-1"
project           = "example"
environment       = "prod"
owner             = "platform-team"
bucket_name       = "example-prod-artifacts"
enable_versioning = true
# In prod, consider lifecycle { prevent_destroy = true } on critical resources
# (set inside the module/resource — lifecycle cannot be parameterized via tfvars).
