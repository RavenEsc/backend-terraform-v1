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
  source_file = "${var.code_dir}/index.py"
  output_path = "${var.code_dir}/lambda_function_payload.zip"
}

resource "aws_lambda_function" "terraform_test_lambda_dynamodb" {
  filename      = data.archive_file.lambda.output_path
  function_name = "terraform-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime       = "python3.10"
}

resource "aws_lambda_permission" "apigw_get_lambda" {
  statement_id  = "AllowGETExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.terraform_test_lambda_dynamodb.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.reg}:${var.accountnumber}:${aws_api_gateway_rest_api.lambda_rest_api.id}/*/${aws_api_gateway_method.get_method.http_method}/"
}

resource "aws_lambda_permission" "apigw_post_lambda" {
  statement_id  = "AllowPOSTExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.terraform_test_lambda_dynamodb.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.reg}:${var.accountnumber}:${aws_api_gateway_rest_api.lambda_rest_api.id}/*/${aws_api_gateway_method.post_method.http_method}/"
}