resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Public web server security group"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-web-sg" }
}

resource "aws_security_group" "controller" {
  name        = "${var.project_name}-controller-sg"
  description = "Private Ansible controller security group"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-controller-sg" }
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-monitoring-sg"
  description = "Private monitoring server security group"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-monitoring-sg" }
}

# Web: public HTTP
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Public application HTTP"
}

# Web: direct SSH only from the student's current public IP
resource "aws_vpc_security_group_ingress_rule" "web_ssh_admin" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Admin SSH to public web/bastion"
}

# Web: Ansible controller can manage the web host privately
resource "aws_vpc_security_group_ingress_rule" "web_ssh_controller" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.controller.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "SSH from Ansible controller"
}

# Web: Node Exporter is visible only to the monitoring server
resource "aws_vpc_security_group_ingress_rule" "web_node_exporter" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.monitoring.id
  from_port                    = 9100
  to_port                      = 9100
  ip_protocol                  = "tcp"
  description                  = "Node Exporter scrape from monitoring host"
}

# Controller is private. It is reached through the public web host as a jump host.
resource "aws_vpc_security_group_ingress_rule" "controller_ssh_from_web" {
  security_group_id            = aws_security_group.controller.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "SSH from public web jump host"
}

# Monitoring is private. Only the controller can SSH to it.
resource "aws_vpc_security_group_ingress_rule" "monitoring_ssh_controller" {
  security_group_id            = aws_security_group.monitoring.id
  referenced_security_group_id = aws_security_group.controller.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "SSH from Ansible controller"
}

# No public ingress is created for Grafana/Prometheus. Cloudflare Tunnel makes outbound connections.

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "controller_all" {
  security_group_id = aws_security_group.controller.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "monitoring_all" {
  security_group_id = aws_security_group.monitoring.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
