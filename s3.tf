# ---------------------------------------------
# S3 static bucket
# ---------------------------------------------
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.project}-${var.environment}-static-contens-terraform"
  acl    = "private"

  website {
    index_document = "image.html"
    error_document = "error.html"
  }
}

# ---------------------------------------------
# バケットポリシー
# ---------------------------------------------
resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket.json
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cf_s3_origin_access_identity.iam_arn]
    }
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}