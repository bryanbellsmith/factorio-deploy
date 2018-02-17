# factorio-deploy

You must set the following environment variable (use set with Windows, export with Unix):

TF_VAR_home_ip="<your IP address>"

You must put your AWS credentials file in the file system above the aws-deploy project folder (so it is excluded from github)

You must create an SSH key within your AWS account called "Home"

You must put your SSH key .pem file in the file system above the aws-deploy project folder (so it is excluded from github)

You must have an S3 bucket with the factorio headless server binaries

terraform plan
terraform apply
terraform destroy