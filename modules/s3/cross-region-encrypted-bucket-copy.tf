variable "app_name" {
  type    = string
}
variable "stage_name" {
  type    = string
}

variable "source_bucket_arn" {
  type = string
}

variable "source_cmk_arn" {
  type = string
}

variable "destination_cmk_arn" {
  type = string
}

resource "random_uuid" "random" {}


# Destination Bucket ----------------------------------------------------------------------

resource "aws_s3_bucket" "destination" {
  bucket = "destination-${random_uuid.random.result}"
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "destination_bpa" {
  bucket = aws_s3_bucket.destination.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "destination_bucket_policy" {
  statement {
    
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.s3_porter_role.arn}"]
    }
    resources = [
      aws_s3_bucket.destination.arn,
      "${aws_s3_bucket.destination.arn}/*"
      ]
  }
}

resource "aws_s3_bucket_policy" "destination_bucket_policy" {
    bucket = aws_s3_bucket.destination.id
    policy = data.aws_iam_policy_document.destination_bucket_policy.json
}

# Destination IAM Role ----------------------------------------------------------------------
# Requires that the source policy (bucket & KMS policy) and the destimation's role resource policy both provide access

data "aws_iam_policy_document" "s3_porter_role_trust_policy" {
  statement {
    actions = [
        "sts:AssumeRole"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::785548451685:root"]
    }
  }
}


data "aws_iam_policy_document" "s3_porter_role_resource_policy" {

    # required 
    statement {
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
      var.source_bucket_arn,
      "${var.source_bucket_arn}/*"
      ]
    }
    
    # optional.
    statement {
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      resources = [
      aws_s3_bucket.destination.arn,
      "${aws_s3_bucket.destination.arn}/*"
      ]
    }
    
    # required
    statement {
      actions = [
        "kms:Decrypt"
      ]
      resources = [
       var.source_cmk_arn
      ]
    }
      
    # optional
    statement {
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
        
      ]
      resources = [
       var.destination_cmk_arn
      ]
    }
}

# s3-porter-role in destination region
resource "aws_iam_role" "s3_porter_role" {
  assume_role_policy = data.aws_iam_policy_document.s3_porter_role_trust_policy.json
}

resource "aws_iam_policy" "s3_porter_role_resource_policy" {
  policy = data.aws_iam_policy_document.s3_porter_role_resource_policy.json
} 

resource "aws_iam_role_policy_attachment" "ts3_porter_role" {
  role       = aws_iam_role.s3_porter_role.name
  policy_arn = aws_iam_policy.s3_porter_role_resource_policy.arn
}