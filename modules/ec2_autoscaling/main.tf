# Default security group for EC2 instances
resource "aws_default_security_group" "default-sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

# Create Launch Template
resource "aws_launch_template" "web_server" {
  image_id      = var.image_id
  instance_type = var.instance_type

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env_prefix}-instance"
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello, World!</h1>" > /usr/share/nginx/html/index.html
            EOF
  )

  # network_interfaces {
  #   security_groups = [aws_default_security_group.default-sg.id]
  # }
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.subnet_ids

  target_group_arns = [var.target_group_arn]
  health_check_type = "ELB"

  min_size         = 1
  max_size         = 5
  desired_capacity = 2

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}