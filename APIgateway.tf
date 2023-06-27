resource "aws_api_gateway_rest_api" "lambda_rest_api" {
  name        = "lambda-function-api"
  description = "Example Rest API"
}

data "aws_api_gateway_resource" "root_method_resource" {
  path     = "/"
  rest_api_id = aws_api_gateway_rest_api.lambda_rest_api.id
}

# METHOD REQUESTS

resource "aws_api_gateway_method" "get_method" {
    rest_api_id   = aws_api_gateway_rest_api.lambda_rest_api.id
    resource_id   = data.aws_api_gateway_resource.root_method_resource.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_rest_api.id
  resource_id   = data.aws_api_gateway_resource.root_method_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# METHOD RESPONSE

resource "aws_api_gateway_method_response" "get_method_response" {
  rest_api_id          = aws_api_gateway_rest_api.lambda_rest_api.id
  resource_id          = data.aws_api_gateway_resource.root_method_resource.id
  http_method          = aws_api_gateway_method.get_method.http_method
  status_code          = "200"
  response_models      = {
    "application/json" = "Empty"
  }
  response_parameters  = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [ aws_api_gateway_method.get_method ]
}

resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id          = aws_api_gateway_rest_api.lambda_rest_api.id
  resource_id          = data.aws_api_gateway_resource.root_method_resource.id
  http_method          = aws_api_gateway_method.post_method.http_method
  status_code          = "200"
  response_models      = {
    "application/json" = "Empty"
  }
  response_parameters  = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [ aws_api_gateway_method.post_method ]
}

# INTEGRATION REQUESTS

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_rest_api.id
  resource_id             = data.aws_api_gateway_resource.root_method_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST" //EVEN IF IT IS A GET METHOD, USE POST FOR LAMBDA INTEGRATIONS LIKE THIS (LAMBDA WILL NOT ACCEPT ANY OTHER INTEGRATION METHOD)
  type                    = "AWS"
  uri                     = aws_lambda_function.terraform_test_lambda_dynamodb.invoke_arn
  depends_on = [ aws_api_gateway_method_response.get_method_response, aws_lambda_function.terraform_test_lambda_dynamodb ]
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_rest_api.id
  resource_id             = data.aws_api_gateway_resource.root_method_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.terraform_test_lambda_dynamodb.invoke_arn
  depends_on = [ aws_api_gateway_method_response.post_method_response, aws_lambda_function.terraform_test_lambda_dynamodb ]
}


# INTEGRATION RESPONSE

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id         = aws_api_gateway_rest_api.lambda_rest_api.id
  resource_id         = data.aws_api_gateway_resource.root_method_resource.id
  http_method         = aws_api_gateway_method.get_method.http_method
  status_code         = aws_api_gateway_method_response.get_method_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'https://www.ravenspencer.com'"
  }
  depends_on = [ aws_api_gateway_integration.get_integration, aws_api_gateway_method.get_method, aws_lambda_function.terraform_test_lambda_dynamodb ]
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id         = aws_api_gateway_rest_api.lambda_rest_api.id
  resource_id         = data.aws_api_gateway_resource.root_method_resource.id
  http_method         = aws_api_gateway_method.post_method.http_method
  status_code         = aws_api_gateway_method_response.post_method_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'https://www.ravenspencer.com'"
  }
  depends_on = [ aws_api_gateway_integration.post_integration, aws_api_gateway_method.post_method, aws_lambda_function.terraform_test_lambda_dynamodb ]
}

# STAGE API

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_rest_api.id
  stage_name    = "prod"
}

# DEPLOY API

resource "aws_api_gateway_deployment" "api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.lambda_rest_api.id
  depends_on  = [ aws_api_gateway_integration.get_integration, aws_api_gateway_integration.post_integration ]
}

output "api_invoke_url" {
  value = "${aws_api_gateway_deployment.api_deploy.invoke_url}prod"
  depends_on = [ aws_api_gateway_deployment.api_deploy ]
}