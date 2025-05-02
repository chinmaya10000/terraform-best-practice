output "alb_dns_name" {
  description = "DNS of the application load balancer"
  value       = aws_lb.web_lb.dns_name
}