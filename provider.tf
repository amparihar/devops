provider "aws" {
  region = var.aws_regions[var.aws_region]
}


module "s3" {
    source = "./modules/s3"
    app_name = var.app_name
    stage_name = var.stage_name
}