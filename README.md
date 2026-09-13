# DevOps Final Project — Automated AWS Deployment & Monitoring

This project implements an end-to-end DevOps environment on AWS using Terraform, Ansible, Docker, Amazon ECR, Prometheus, Grafana, Cloudflare Tunnel, GitHub and GitHub Actions.

## Architecture

```text
Internet
   |
   +--> Application domain / Web Elastic IP
   |            |
   |        WEB EC2
   |        10.0.0.5
   |        Docker
   |        +-- Application image from ECR :80
   |        +-- Node Exporter :9100
   |
   +--> Cloudflare
             |
       outbound Tunnel
             |
       MONITORING EC2 (private)
       10.0.0.136
       +-- Prometheus
       +-- Grafana

                 PRIVATE SUBNET 10.0.0.128/25
                 +----------------------------+
                 | Controller 10.0.0.135      |
                 | Monitoring 10.0.0.136      |
                 +----------------------------+
                          |
                     NAT Gateway
                          |
PUBLIC SUBNET 10.0.0.0/25
+-----------------------------+
| Web 10.0.0.5                |
| NAT Gateway                 |
+-----------------------------+
          |
   Internet Gateway

VPC: 10.0.0.0/24
Terraform remote state: Amazon S3
Container registry: Amazon ECR
Configuration management: Ansible controller
Documentation: GitHub Pages via GitHub Actions
```

## Fixed Network Values

| Component | Value |
|---|---|
| AWS Region | `ap-southeast-1` |
| VPC | `10.0.0.0/24` |
| Public subnet | `10.0.0.0/25` |
| Private subnet | `10.0.0.128/25` |
| Web server | `10.0.0.5` |
| Ansible controller | `10.0.0.135` |
| Monitoring server | `10.0.0.136` |

## Repository Layout

```text
.
├── app/                       # Existing bootcamp application and Dockerfile
├── terraform/
│   ├── bootstrap/             # S3 remote-state bucket
│   └── main/                  # VPC, subnets, SGs, EC2, EIP, IAM, ECR
├── ansible/
│   ├── inventory.ini
│   ├── playbooks/
│   └── roles/
├── scripts/
│   ├── push-ecr.sh
│   └── verify.sh
├── docs/evidence/
└── .github/workflows/pages.yml
```

## 1. Prerequisites

Local/WSL tools:

```bash
git --version
aws --version
terraform version
ansible --version
```

Confirm AWS authentication:

```bash
aws sts get-caller-identity
aws configure get region
```

Region must be `ap-southeast-1`.

Do not commit AWS credentials, `.pem` files, `terraform.tfstate`, `terraform.tfvars`, Cloudflare tokens or Grafana passwords.

## 2. Bootstrap the S3 Terraform Backend

```bash
cd terraform/bootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform output -raw terraform_state_bucket
```

Copy the printed bucket name.

## 3. Provision the AWS Infrastructure

Find your current public IPv4:

```bash
curl -4 ifconfig.me
```

Create the local variables file:

```bash
cd ../main
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:

```hcl
key_name   = "syam9-key"
admin_cidr = "YOUR_PUBLIC_IP/32"
```

Initialize the remote backend using the bucket from Step 2:

```bash
terraform init \
  -backend-config="bucket=YOUR_TFSTATE_BUCKET" \
  -backend-config="key=final/terraform.tfstate" \
  -backend-config="region=ap-southeast-1"

terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Expected fixed private IPs:

```text
Web:        10.0.0.5
Controller: 10.0.0.135
Monitoring: 10.0.0.136
```

The monitoring EC2 instance has no public IP and no public Grafana/Prometheus ingress rule.

## 4. Build and Push the Application to Amazon ECR

The helper can run either on local WSL (if Docker is available) **or on the private Ansible controller** after the repository is cloned there. The controller is provisioned with Docker, AWS CLI and a repository-scoped ECR push policy, so local Docker is not a blocker.

From the repository root:

```bash
./scripts/push-ecr.sh
```

If running on the controller for the first time, start a new login shell (or run `newgrp docker`) so the `ubuntu` user's Docker group membership is active.

Verify:

```bash
aws ecr describe-images \
  --repository-name devops-final-app \
  --region ap-southeast-1 \
  --output table
```

## 5. Access the Private Ansible Controller

The public web server is used only as an SSH jump host for administration.

Get the web Elastic IP:

```bash
terraform -chdir=terraform/main output -raw web_elastic_ip
```

Copy the SSH key to the controller through the jump host (do not put the key in Git):

```bash
WEB_IP=$(terraform -chdir=terraform/main output -raw web_elastic_ip)
scp -o ProxyJump=ubuntu@${WEB_IP} -i ~/.ssh/syam9-key \
  ~/.ssh/syam9-key ubuntu@10.0.0.135:/home/ubuntu/.ssh/syam9-key
```

Set the key permissions on the controller:

```bash
ssh -J ubuntu@${WEB_IP} -i ~/.ssh/syam9-key ubuntu@10.0.0.135 \
  'chmod 600 ~/.ssh/syam9-key'
```

Copy/clone this public repository on the controller, then enter `ansible/`.

Example controller login:

```bash
ssh -J ubuntu@${WEB_IP} -i ~/.ssh/syam9-key ubuntu@10.0.0.135
```

## 6. Configure the Servers with Ansible

On the controller:

```bash
cd ~/devops-final-project/ansible
ansible all -m ping
```

Set the Grafana password only in the shell environment:

```bash
export GRAFANA_ADMIN_PASSWORD='REPLACE_WITH_STRONG_PASSWORD'
ansible-playbook playbooks/site.yml
```

Do not commit this password.

The playbook:

- installs Docker using Ansible;
- deploys the application image from private ECR to the web server;
- runs Node Exporter on the web server;
- deploys Prometheus and Grafana on the private monitoring server;
- provisions the Prometheus datasource and Grafana dashboard automatically.

Re-running the playbook is safe and converges the Docker Compose stacks to the declared configuration.

## 7. Verify Prometheus and Grafana Internally

From the controller:

```bash
ssh -i ~/.ssh/syam9-key ubuntu@10.0.0.136
```

On monitoring:

```bash
sudo docker ps
curl -s http://127.0.0.1:9090/-/healthy
curl -I http://127.0.0.1:3000/login
```

Prometheus should report `10.0.0.5:9100` as `UP`.

## 8. Configure Cloudflare Tunnel

Create a Cloudflare Tunnel in Cloudflare and map your monitoring hostname to:

```text
http://localhost:3000
```

Copy the tunnel token and store it in AWS SSM Parameter Store from your local WSL terminal:

```bash
read -s CF_TOKEN
aws ssm put-parameter \
  --name /devops-final/cloudflare-tunnel-token \
  --type SecureString \
  --value "$CF_TOKEN" \
  --overwrite \
  --region ap-southeast-1
unset CF_TOKEN
```

Run the tunnel playbook from the Ansible controller:

```bash
ansible-playbook playbooks/cloudflare.yml
```

Verify on the monitoring host:

```bash
sudo docker ps | grep cloudflared
```

The monitoring security group intentionally has **no public inbound rule for port 3000 or 9090**. The tunnel originates outbound from the private monitoring server.

Configure the Cloudflare SSL/TLS mode required by the assignment, then verify the monitoring URL externally.

## 9. Application Domain

Point the required application hostname to the Terraform output `web_elastic_ip` using your DNS/Cloudflare configuration.

Verify:

```bash
curl -I http://YOUR_APPLICATION_DOMAIN
```

## 10. GitHub Pages Documentation

The workflow `.github/workflows/pages.yml` automatically publishes this README as the GitHub Pages home page whenever documentation changes are pushed to `main`.

In the GitHub repository:

1. Open **Settings → Pages**.
2. Set **Source** to **GitHub Actions**.
3. Push to `main`.
4. Open **Actions** and verify `Publish Project Documentation` succeeds.

## 11. Validation Evidence

Before submission, add non-sensitive screenshots to `docs/evidence/`.

Required evidence should clearly show:

- S3 remote-state bucket;
- VPC, public/private subnets, Internet Gateway, NAT Gateway and route tables;
- Security Groups;
- three running EC2 instances and fixed private IPs;
- ECR repository with the application image;
- successful Ansible execution;
- application container and Node Exporter;
- Prometheus target `UP`;
- Grafana dashboard;
- healthy Cloudflare Tunnel;
- live application URL;
- live monitoring URL;
- GitHub Pages documentation URL.

## 12. Submission URLs

Fill these in before submission:

| Item | URL / value |
|---|---|
| Application | `TODO` |
| Monitoring / Grafana | `TODO` |
| GitHub repository | `TODO` |
| GitHub Pages documentation | `TODO` |
| Grafana username | `admin` |
| Grafana password | Submit privately through the required submission channel; do not commit it |

## 13. Cleanup After Assessment

Do **not** destroy the environment before the assessor has completed the review.

After assessment is confirmed complete:

```bash
terraform -chdir=terraform/main destroy
```

The S3 backend can be deleted separately only after Terraform state is no longer required.

---

## Reused Bootcamp Work

This final project deliberately consolidates earlier bootcamp practical work into one end-to-end environment. The application Dockerfile, Terraform patterns, Ansible automation, Prometheus configuration and Grafana dashboard were adapted from the student's own prior bootcamp exercises and reorganized to match the final-project architecture and fixed IP plan.
