# provider "aws" {
#   region = var.aws_region
# }

# # Create S3 bucket for backend
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "chinmaya-terraform-state"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# # Enable versioning on the S3 bucket
# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # Enable server-side encryption on the bucket
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#     }
#   }
# }

# # Block all public access to the bucket
# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # Create DynamoDB table for state lockin
# resource "aws_dynamodb_table" "terraform_state" {
#   name = "chinmaya-terraform-state-lock"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }
