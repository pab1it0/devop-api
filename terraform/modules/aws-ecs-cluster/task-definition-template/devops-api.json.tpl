[{
  "essential": true,
  "image": "${image}",
  "name": "${resource_prefix}",
  "portMappings": [{
    "containerPort": ${container_port},
    "hostPort": ${container_port}
  }
  ],
  "user": "0",
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${resource_prefix}-proxy",
      "awslogs-region": "${aws_region}",
      "awslogs-stream-prefix": "ecs"
    }
  }
}]