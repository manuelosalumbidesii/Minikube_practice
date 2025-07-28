# This Terraform setup deploys a simple ECS Fargate microservice
# that can upload files to an S3 bucket.

provider "aws" {
  region = "us-east-1"
}

# 1. Create the S3 Bucket
resource "aws_s3_bucket" "uploads" {
  bucket        = "my-upload-microservice-bucket"
  force_destroy = true
}

# 2. IAM Policy for S3 Access
resource "aws_iam_policy" "s3_access" {
  name = "ecs-s3-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = [
          aws_s3_bucket.uploads.arn,
          "${aws_s3_bucket.uploads.arn}/*"
        ]
      }
    ]
  })
}

# 3. IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# 4. Attach S3 Policy to ECS Task Role
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# 5. IAM Role for ECS Execution (pull image, logging)
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 6. ECS Task Definition
resource "aws_ecs_task_definition" "upload_task" {
  family                   = "upload-microservice"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "upload-app",
      image     = "your-ecr-uri/upload-app:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ]
    }
  ])
}

# 7. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "upload-cluster"
}

# 8. VPC, Subnets, Security Group (simplified placeholder)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "upload-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-service-sg"
  description = "Allow HTTP access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 9. ECS Service
resource "aws_ecs_service" "upload_service" {
  name            = "upload-service"
  cluster         = aws_ecs_cluster.main.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.upload_task.arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.public_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}
