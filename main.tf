provider "aws" {
  region     = var.region
  #shared_credentials_files = ["C:/Users/piyush_yogi/.aws/credentials"]

}


resource "aws_iam_role" "my_role" {
  name = var.name_of_role


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    name = "my_lambda"
  }
}

# IAM policy for logging from a lambda

resource "aws_iam_policy" "policy" {
  name        = var.name_of_policy
  path        = "/"
  description = "My policy"


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.my_role.name
  policy_arn  = aws_iam_policy.policy.arn
}

# Generating an archive from content.

data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/hello-python.zip"
}


resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket}/*"
            ]
        }
    ]
}
POLICY
}
 

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id



  lambda_function {
    lambda_function_arn = aws_lambda_function.terraform_lambda_func.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_prefix       = ""
    filter_suffix       = ""
  }

  depends_on = [aws_lambda_permission.allow_bucket]
  
}


resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:*"
  function_name = aws_lambda_function.terraform_lambda_func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_lambda_function" "terraform_lambda_func" {
 filename                       = "${path.module}/python/hello-python.zip"
 function_name                  = var.function_name
 role                           = aws_iam_role.my_role.arn
 handler                        = "hello-python.lambda_handler"
 runtime                        = var.runtime
 depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}
#Uploadind tfstate file to S3 bucket
/*terraform {
  backend "s3"{
    bucket = "piyushyogi121998"
    key = "mystatefile/terraform.tfstate"
    region = "ap-south-1"

  }
}
*/









