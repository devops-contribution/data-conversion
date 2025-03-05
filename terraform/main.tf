provider "aws" {
  region = var.aws_region
}

locals {
  name = "velotio"
}

# S3 Buckets - bucket for manually uploading csv
resource "aws_s3_bucket" "csv_bucket" {
  bucket = "custom-csv-bucket-${local.name}"
  force_destroy = true
}

# S3 Bucket -  bucket for storing the json converted data
resource "aws_s3_bucket" "json_bucket" {
  bucket = "custom-json-bucket-${local.name}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "json_versioning" {
  bucket = aws_s3_bucket.json_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.csv_bucket.id
  eventbridge = true
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name        = "s3-upload-event-rule-${local.name}"
  description = "Capture S3 object creation events"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["${aws_s3_bucket.csv_bucket.id}"]
    }
  }
}
EOF
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "lambda-s3-event-role-${local.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# IAM Policy for Lambda to access S3 and SNS
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-s3-policy-${local.name}"
  description = "IAM policy for Lambda to access S3 and SNS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["${aws_s3_bucket.csv_bucket.arn}/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": ["${aws_s3_bucket.json_bucket.arn}/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["sns:Publish"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": ["arn:aws:logs:*:*:*"]
    }
  ]
}
EOF
}

# Attach IAM Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "file_processor_lambda" {
  function_name    = "s3-file-processor-${local.name}"
  role            = aws_iam_role.lambda_role.arn
  timeout         = 10
  memory_size     = 2048
  runtime         = "python3.9"
  handler         = "lambda_function.lambda_handler"
  filename        = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      CSV_BUCKET = aws_s3_bucket.csv_bucket.id
      JSON_BUCKET = aws_s3_bucket.json_bucket.id
      SNS_TOPIC_ARN = aws_sns_topic.alert_topic.arn
    }
  }
}

# EventBridge Target to trigger Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_event_rule.name
  arn       = aws_lambda_function.file_processor_lambda.arn
}

# Grant EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "eventbridge_lambda_permission" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_processor_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_event_rule.arn
}

# SNS Topic for alerts
resource "aws_sns_topic" "alert_topic" {
  name = "s3-upload-alerts-${local.name}"
}

# SNS Subscription to send email
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = "mukesh.rawat@velotio.com"
}
