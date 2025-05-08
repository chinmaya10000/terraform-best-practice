resource "aws_ecs_cluster" "ecs_cluster" {
  name = "bankapp-cluster"
}

resource "aws_ecs_task_definition" "bankapp" {
  family                   = "bankapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
    {
      name      = "bankapp"
      image     = "chinmayapradhan/bankapp:1.0"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:mysql://${aws_db_instance.mysql.address}:3306/bankappdb?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
        },
        {
          name  = "SPRING_DATASOURCE_USERNAME"
          value = "root"
        },
        {
          name  = "SPRING_DATASOURCE_PASSWORD"
          value = "Test@123"
        }
      ]
    }
  ])

  depends_on = [aws_iam_role.ecs_task_exec]
}

resource "aws_lb" "bankapp_alb" {
  name               = "bankapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "bankapp_tg" {
  name        = "bankapp-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "bankapp_listener" {
  load_balancer_arn = aws_lb.bankapp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bankapp_tg.arn
  }
}

resource "aws_ecs_service" "bankapp_service" {
  name            = "bankapp-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.bankapp.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bankapp_tg.arn
    container_name   = "bankapp"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.bankapp_listener, aws_db_instance.mysql]
}