# AWS Web Application Infrastructure (Terraform)

Three-tier, highly available web stack on AWS, defined entirely in Terraform.

## File layout

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform, provider config, default tags |
| `variables.tf` | All inputs with defaults |
| `network.tf` | VPC, subnets, IGW, NAT Gateways, route tables |
| `security_groups.tf` | `alb-sg`, `web-sg`, `db-sg` |
| `iam.tf` | EC2 role, SSM policy attachment, instance profile |
| `alb.tf` | ALB, target group, listener |
| `compute.tf` | Launch template, ASG, scaling policies, CloudWatch alarms |
| `rds.tf` | DB subnet group and RDS instance |
| `user_data.sh` | Installs Nginx and serves "Hello World" |
| `outputs.tf` | ALB DNS name, IDs, DB endpoint, secret ARN |

