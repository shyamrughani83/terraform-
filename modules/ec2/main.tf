data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-ec2-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eip" "app_server" {
  domain = "vpc"
  instance = aws_instance.app_server.id

  tags = {
    Name        = "${var.project_name}-ec2-eip-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}
