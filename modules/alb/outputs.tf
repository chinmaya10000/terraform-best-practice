output "alb_dns_name" {
  value = aws_lb.web_lb.dns_name
  description = "The DNS name of the ALB"
}

output "alb_sg_id" {
  value = aws_security_group.alb-sg.id
  description = "The security group ID of the ALB"
}

output "target_group_arn" {
  value = aws_lb_target_group.web_tg.arn
  description = "The ARN of the target group"
}