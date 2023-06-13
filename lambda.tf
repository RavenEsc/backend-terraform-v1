data "aws_iam_policy_document" "main_lambda_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "dynamodblambda_policy" {
  name        = "dynamodb_policy"
  path        = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.reg}:${var.accountnumber}:table/${var.tablename}"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name               = "Lambda_role"
  assume_role_policy = data.aws_iam_policy_document.main_lambda_policy.json
}

resource "aws_iam_role_policy" "dynamodb_visitor_counter_policy" {
  name   = "dynamodb_visitor_counter_policy"
  role   = aws_iam_role.lambda_role.id
  policy = aws_iam_policy.dynamodblambda_policy.policy
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "index.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "terraform_test_lambda_dynamodb" {
  filename      = "lambda_function_payload.zip"
  function_name = "terraform-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime       = "python3.10"
}
