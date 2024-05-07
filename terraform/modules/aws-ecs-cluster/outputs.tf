output "ecs_lb_edpoint" {
  value = aws_alb.alb.dns_name
}