resource "aws_ecr_repository" "app" {
  name                 = "devops-final-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
