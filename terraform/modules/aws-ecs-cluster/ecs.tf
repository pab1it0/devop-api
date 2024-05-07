resource "aws_ecs_cluster" "cluster" {
  name = "${var.resource_prefix}-ecs-cluster"
}

data "template_file" "task-def" {
  template = file("${path.module}/task-definition-template/devops-api.json.tpl")

  vars = {
    image           = var.devops_api_image_name
    container_name  = var.resource_prefix
    container_port  = var.container_port
    resource_prefix = var.resource_prefix
    aws_region      = var.aws_region
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  container_definitions    = data.template_file.task-def.rendered
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  family                   = "${var.resource_prefix}-task"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  depends_on = [
    aws_cloudwatch_log_group.fargate-lg
  ]
}

resource "aws_cloudwatch_log_group" "fargate-lg" {
  name              = "${var.resource_prefix}-proxy"
  retention_in_days = 7
}

resource "aws_ecs_service" "svc" {
  desired_count = 1
  name          = "${var.resource_prefix}-svc"
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = var.resource_prefix
    container_port   = var.container_port
  }
  launch_type = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.allow_svc.id]
    subnets         = var.private_subnets
  }

  task_definition = aws_ecs_task_definition.task_definition.arn
  cluster         = aws_ecs_cluster.cluster.id
  depends_on = [
    aws_ecs_task_definition.task_definition
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener_rule" "path_based_weighted_routing" {
  listener_arn = aws_alb_listener.main.arn
  priority     = 97
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb" "alb" {
  name               = "${var.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_ingress_443.id]
  subnets            = var.public_subnets

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "lb_ingress_443" {
  vpc_id = var.vpc_id
  egress = [{
    description      = "allow alb to svc"
    protocol         = -1
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    self             = null
    security_groups  = null
  }]
  ingress = [{
    description      = "allow http to alb"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    self             = null
    security_groups  = null
  }]
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name                 = "${var.resource_prefix}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    protocol            = "HTTP"
    path                = "/v1/health"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    effect = "Allow"

    resources = ["${var.devops_api_ecr_arn}"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.resource_prefix}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attach" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.resource_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "${var.resource_prefix}-log-permissions"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json
}

resource "aws_security_group" "allow_svc" {
  vpc_id = var.vpc_id
  ingress = [{
    description      = "allow svc from alb"
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    self             = null
    security_groups  = null
  }]
  egress = [{
    description      = "allow internet to fargate"
    protocol         = -1
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    self             = null
    security_groups  = null
  }]
}

resource "aws_security_group" "allow_alb_to_svc" {
  vpc_id = var.vpc_id
  egress = [{
    description      = "allow lb to service"
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    self             = null
    security_groups  = null
  }]
}