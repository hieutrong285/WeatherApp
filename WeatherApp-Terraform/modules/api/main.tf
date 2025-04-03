resource "aws_lambda_function" "oauth2_authorizer" {
  filename         = "${path.module}/lambda_authorizer.zip"
  function_name    = "OAuth2Authorizer"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/lambda_authorizer.zip")
}

######### IAM-FOR-LAMBDA ############

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

########## API-GATEWAY-AUTHORIZER #############

resource "aws_api_gateway_rest_api" "weather_api" {
  name        = "WeatherAPI"
  description = "API for Weather Forecasting Application"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_rest_api.weather_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_authorizer" "weather_authorizer" {
  name                       = "WeatherAPIAuthorizer"
  rest_api_id                = aws_api_gateway_rest_api.weather_api.id
  authorizer_uri             = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.oauth2_authorizer.arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  type                       = "TOKEN"
}

resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.oauth2_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  # Allow API Gateway to invoke the Lambda authorizer
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.weather_api.id}/*"
}

############ API-GATEWAY-METHOD ################

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.weather_authorizer.id
}
