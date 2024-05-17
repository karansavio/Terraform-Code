
# Deploy the module to eu-west-1 region
terraform {
   source =  "file:///Users/karanchoudhary/Documents/Terraform-Code/"
  extra_arguments "eu-west-1" {
    commands = ["apply"]
    arguments = ["-var", "region=eu-west-1"]
  }
}
