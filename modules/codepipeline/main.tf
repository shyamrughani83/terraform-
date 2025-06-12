resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project_name}-artifacts-${var.environment}"

  tags = {
    Name        = "${var.project_name}-artifacts-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "artifacts" {
  depends_on = [aws_s3_bucket_ownership_controls.artifacts]
  bucket     = aws_s3_bucket.artifacts.id
  acl        = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role-${var.environment}"

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
    Name        = "${var.project_name}-codepipeline-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-codepipeline-policy-${var.environment}"
  role = aws_iam_role.codepipeline_role.id

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
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
        Effect   = "Allow"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.build.arn
        Effect   = "Allow"
      },
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

# GitHub connection for CodePipeline
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-gh-conn-${var.environment}"
  provider_type = "GitHub"
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role-${var.environment}"

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
    Name        = "${var.project_name}-codebuild-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name}-codebuild-policy-${var.environment}"
  role = aws_iam_role.codebuild_role.id

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
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_codebuild_project" "build" {
  name          = "${var.project_name}-build-${var.environment}"
  description   = "Build project for ${var.project_name}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 10

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "ap-south-1"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "ACCOUNT_ID_PLACEHOLDER"
    }

    environment_variable {
      name  = "ECR_REPOSITORY_NAME"
      value = "${var.project_name}-repo-${var.environment}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = {
    Name        = "${var.project_name}-build-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_codepipeline" "main" {
  name     = "${var.project_name}-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
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
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repository
        BranchName       = var.branch_name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAndPushToECR"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-pipeline-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create a sample buildspec.yml file in the project directory
resource "local_file" "buildspec" {
  content = <<-EOT
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPOSITORY_NAME
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=$${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $${REPOSITORY_URI}:latest
      - docker push $${REPOSITORY_URI}:$${IMAGE_TAG}
      - echo Writing image definitions file...
      - echo "[{\"name\":\"${var.project_name}-container-${var.environment}\",\"imageUri\":\"$${REPOSITORY_URI}:$${IMAGE_TAG}\"}]" > imagedefinitions.json
artifacts:
  files:
    - imagedefinitions.json
    - appspec.yml
    - taskdef.json
  EOT

  filename = "${path.module}/buildspec.yml"
}
