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

# ----------  S3 bucket for static site  ----------
resource "aws_s3_bucket" "frontend" {
  bucket        = "code-detector-frontend-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = false 
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "frontend-oac-${random_id.suffix.hex}"
  description                       = "Origin Access Control for Frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "frontendS3"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "frontendS3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" 
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Frontend CloudFront Distribution"
    Environment = "production"
  }
}

data "aws_iam_policy_document" "frontend_cloudfront" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_cloudfront" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_cloudfront.json

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

data "template_file" "frontend_cfg" {
  template = <<EOF
// Generated by Terraform
window.CodeDetectorConfig = {
  apiUrl: "${aws_apigatewayv2_api.api.api_endpoint}/detect",
  apiKey: "${var.detector_api_key}"
};
EOF
}

resource "aws_s3_object" "cfg_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "config.js"
  content      = data.template_file.frontend_cfg.rendered
  content_type = "application/javascript"
  etag         = md5(data.template_file.frontend_cfg.rendered)

  depends_on = [aws_s3_bucket_policy.frontend_cloudfront]
}

locals {
  static_files = {
    "index.html" = "text/html"
    "script.js"  = "application/javascript"
    "styles.css" = "text/css"
  }
}

resource "aws_s3_object" "static_files" {
  for_each = local.static_files

  bucket       = aws_s3_bucket.frontend.id
  key          = each.key
  source       = "${path.module}/${each.key}"
  content_type = each.value
  etag         = filemd5("${path.module}/${each.key}")

  depends_on = [aws_s3_bucket_policy.frontend_cloudfront]
}

