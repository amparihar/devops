variable "app_name" {
  type    = string
  default = "devops"
}
variable "stage_name" {
  type    = string
  default = "develop"
}

variable "aws_region" {
  type    = string
  default = "ohio"
}
variable "aws_regions" {
  type = map(string)
  default = {
    mumbai        = "ap-south-1"
    northvirginia = "us-east-1"
    ohio          = "us-east-2"
  }
}