provider "aws" {
  region = var.aws_regions[var.aws_region]
}


module "s3" {
    source = "./modules/s3"
    app_name = var.app_name
    stage_name = var.stage_name
    source_bucket_arn = var.source_bucket_arn
    source_cmk_arn = var.source_cmk_arn
    destination_cmk_arn = var.destination_cmk_arn
}