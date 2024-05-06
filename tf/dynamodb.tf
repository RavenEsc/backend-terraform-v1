resource "aws_dynamodb_table" "counter-db" {
  name           = var.tablename
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = var.hashkey

  attribute {
    name = var.hashkey
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-2"
    Environment = "production"
  }
}