terraform {
  backend "s3" {
    bucket = "s3-bucket-name"
    key    = "/"
    region = "us-east-1"
    dynamodb_table = "dynamodb-table-lock"
  }
}
