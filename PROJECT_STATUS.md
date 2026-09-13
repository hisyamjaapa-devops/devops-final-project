# Submission-Day Rescue Checklist

## P0 — Must be working before submission

- [ ] AWS CLI authenticated in `ap-southeast-1`
- [ ] GitHub public repository created and code pushed
- [ ] S3 remote backend created
- [ ] Terraform main stack applies successfully
- [ ] Web = `10.0.0.5`
- [ ] Controller = `10.0.0.135`
- [ ] Monitoring = `10.0.0.136`
- [ ] ECR image exists
- [ ] Application URL works
- [ ] Ansible executed from controller
- [ ] Node Exporter target is UP in Prometheus
- [ ] Grafana dashboard works
- [ ] Cloudflare Tunnel works
- [ ] Monitoring has no public inbound 3000/9090
- [ ] GitHub Pages works
- [ ] README contains final URLs
- [ ] Grafana login supplied privately to assessor

## P1 — Evidence

- [ ] AWS infrastructure screenshots
- [ ] ECR image screenshot
- [ ] Ansible success screenshot
- [ ] Prometheus targets screenshot
- [ ] Grafana screenshot
- [ ] Cloudflare tunnel screenshot
- [ ] GitHub Actions Pages success screenshot

## P2 — Only if P0/P1 are complete

- [ ] Optional application CI/CD to ECR
- [ ] Optional automated deployment after ECR push
- [ ] Optional Terraform PR plan gate
- [ ] Optional format/lint checks
