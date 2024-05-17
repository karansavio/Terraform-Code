#Backend S3 Bucket assignment for multiple region deployment

# #Creating an S3 bucket for multi-region deployment
terraform {
  backend "s3" {
    bucket = "my-terraform-state-ecs-fargate"
    key    = "eu-west-1/Terraform-Code/terraform.tfstate"
    region = "eu-west-1"
  }
}


