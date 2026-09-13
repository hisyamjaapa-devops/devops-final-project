output "web_elastic_ip" {
  value = aws_eip.web.public_ip
}

output "web_private_ip" {
  value = aws_instance.web.private_ip
}

output "controller_private_ip" {
  value = aws_instance.controller.private_ip
}

output "monitoring_private_ip" {
  value = aws_instance.monitoring.private_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ssh_controller_via_web" {
  value = "ssh -J ubuntu@${aws_eip.web.public_ip} -i ~/.ssh/syam9-key ubuntu@10.0.0.135"
}
