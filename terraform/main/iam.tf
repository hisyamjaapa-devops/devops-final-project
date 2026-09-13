data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.project_name}-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "web_ecr_read" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.project_name}-web-profile"
  role = aws_iam_role.web.name
}

resource "aws_iam_role" "controller" {
  name               = "${var.project_name}-controller-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "controller_ssm" {
  role       = aws_iam_role.controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "controller_ecr_push" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_policy" "controller_ecr_push" {
  name   = "${var.project_name}-controller-ecr-push"
  policy = data.aws_iam_policy_document.controller_ecr_push.json
}

resource "aws_iam_role_policy_attachment" "controller_ecr_push" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller_ecr_push.arn
}

resource "aws_iam_instance_profile" "controller" {
  name = "${var.project_name}-controller-profile"
  role = aws_iam_role.controller.name
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.project_name}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "monitoring_cloudflare_token" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/devops-final/cloudflare-tunnel-token"
    ]
  }
}

resource "aws_iam_policy" "monitoring_cloudflare_token" {
  name   = "${var.project_name}-cloudflare-token-read"
  policy = data.aws_iam_policy_document.monitoring_cloudflare_token.json
}

resource "aws_iam_role_policy_attachment" "monitoring_cloudflare_token" {
  role       = aws_iam_role.monitoring.name
  policy_arn = aws_iam_policy.monitoring_cloudflare_token.arn
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.project_name}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}
