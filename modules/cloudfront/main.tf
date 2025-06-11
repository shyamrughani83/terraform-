resource "aws_s3_bucket" "static_website" {
  bucket = "${var.project_name}-static-${var.environment}"

  tags = {
    Name        = "${var.project_name}-static-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_ownership_controls" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_origin_access_identity" "static_website" {
  comment = "OAI for ${var.project_name} static website"
}

resource "aws_s3_bucket_policy" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.static_website.id}"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "static_website" {
  origin {
    domain_name = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_website.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static_website.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_website.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
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
    Name        = "${var.project_name}-cloudfront-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CodePipeline for static website
resource "aws_s3_bucket" "static_artifacts" {
  bucket = "${var.project_name}-static-artifacts-${var.environment}"

  tags = {
    Name        = "${var.project_name}-static-artifacts-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_ownership_controls" "static_artifacts" {
  bucket = aws_s3_bucket.static_artifacts.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "static_artifacts" {
  depends_on = [aws_s3_bucket_ownership_controls.static_artifacts]
  bucket     = aws_s3_bucket.static_artifacts.id
  acl        = "private"
}

resource "aws_iam_role" "static_codepipeline_role" {
  name = "${var.project_name}-static-pipeline-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-static-pipeline-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "static_codepipeline_policy" {
  name = "${var.project_name}-static-pipeline-policy-${var.environment}"
  role = aws_iam_role.static_codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.static_artifacts.arn,
          "${aws_s3_bucket.static_artifacts.arn}/*",
          aws_s3_bucket.static_website.arn,
          "${aws_s3_bucket.static_website.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.static_github.arn
        Effect   = "Allow"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.static_build.arn
        Effect   = "Allow"
      },
      {
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = aws_cloudfront_distribution.static_website.arn
        Effect   = "Allow"
      }
    ]
  })
}

# GitHub connection for static website CodePipeline
resource "aws_codestarconnections_connection" "static_github" {
  name          = "${var.project_name}-static-gh-conn-${var.environment}"
  provider_type = "GitHub"
}

resource "aws_iam_role" "static_codebuild_role" {
  name = "${var.project_name}-static-build-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-static-build-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "static_codebuild_policy" {
  name = "${var.project_name}-static-build-policy-${var.environment}"
  role = aws_iam_role.static_codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.static_artifacts.arn,
          "${aws_s3_bucket.static_artifacts.arn}/*",
          aws_s3_bucket.static_website.arn,
          "${aws_s3_bucket.static_website.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = aws_cloudfront_distribution.static_website.arn
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_codebuild_project" "static_build" {
  name          = "${var.project_name}-static-build-${var.environment}"
  description   = "Build project for ${var.project_name} static website"
  service_role  = aws_iam_role.static_codebuild_role.arn
  build_timeout = 10

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.static_website.bucket
    }

    environment_variable {
      name  = "CLOUDFRONT_DISTRIBUTION_ID"
      value = aws_cloudfront_distribution.static_website.id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-static.yml"
  }

  tags = {
    Name        = "${var.project_name}-static-build-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_codepipeline" "static_website" {
  name     = "${var.project_name}-static-pipeline-${var.environment}"
  role_arn = aws_iam_role.static_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.static_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.static_github.arn
        FullRepositoryId = var.static_github_repository
        BranchName       = var.static_branch_name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAndDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.static_build.name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-static-pipeline-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create a sample buildspec-static.yml file
resource "local_file" "buildspec_static" {
  filename = "${path.root}/buildspec-static.yml"
  content = <<-EOT
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 16
    commands:
      - echo Installing dependencies...
      - npm install
  build:
    commands:
      - echo Build started on `date`
      - npm run build
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Deploying to S3...
      - aws s3 sync build/ s3://$S3_BUCKET/ --delete
      - echo Creating CloudFront invalidation...
      - aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*"

artifacts:
  base-directory: build
  files:
    - '**/*'
  EOT
}
