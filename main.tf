provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec" {
  name = "code-detector-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "bedrock_policy" {
  name = "bedrock-lambda-policy"
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "bedrock:InvokeModel",
          "bedrock:ListModels",
          "logs:*"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" = [
          aws_s3_bucket.code_results.arn,
          "${aws_s3_bucket.code_results.arn}/*"
        ]
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData"
        ],
        "Resource" = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.bedrock_policy.arn
}

resource "aws_lambda_function" "code_detector" {
  function_name        = "code-detector"
  role                = aws_iam_role.lambda_exec.arn
  handler             = "handler.lambda_handler"
  runtime             = "python3.11"
  filename            = "${path.module}/lambda/code_detector.zip"
  source_code_hash    = filebase64sha256("${path.module}/lambda/code_detector.zip")
  timeout             = 30

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.code_results.bucket
      METRIC_NS = "CodeDetector"
      EXPECTED_API_KEY = var.detector_api_key
    }
  }
}

resource "aws_apigatewayv2_api" "api" {
  name          = "CodeDetectorAPI"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["POST", "OPTIONS"]
    allow_origins = ["*"]
    allow_headers = ["Content-Type", "x-api-key"]
    max_age = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.code_detector.invoke_arn
}

resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /detect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.code_detector.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_s3_bucket" "code_results" {
  bucket = "${var.s3_bucket_name}-${random_id.suffix.hex}"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.code_detector.function_name}"
  retention_in_days = 60
  
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_high" {
  alarm_name          = "CodeDetectorLambdaErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300              
  statistic           = "Sum"
  threshold           = 1                
  dimensions = {
    FunctionName = aws_lambda_function.code_detector.function_name
  }
  alarm_description   = "Lambda is throwing errors"
  treat_missing_data  = "notBreaching"
}

resource "aws_iam_role" "grafana_service" {
  name = "GrafanaServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "grafana.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_cw_attach" {
  role       = aws_iam_role.grafana_service.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_grafana_workspace" "code_detector_grafana" {
  name                     = "code-detector-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  data_sources             = ["CLOUDWATCH"]
  role_arn                 = aws_iam_role.grafana_service.arn  
  permission_type          = "SERVICE_MANAGED"
}

data "aws_identitystore_user" "grafana_admin" {
  identity_store_id = var.identitystore_id        

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = var.grafana_admin_username   
    }
  }
}

resource "aws_grafana_role_association" "admin_user" {
  workspace_id = aws_grafana_workspace.code_detector_grafana.id
  role         = "ADMIN"
  user_ids     = [data.aws_identitystore_user.grafana_admin.user_id]
  group_ids    = []                                  
}
