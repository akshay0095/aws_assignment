# AWS Web Application Infrastructure (Terraform)

Three-tier, highly available web stack on AWS, defined entirely in Terraform.

## Architecture

```
                    Internet
                       |
                 [ Internet Gateway ]
                       |
   +-------------------+--------------------+   VPC 10.0.0.0/16
   |  AZ-a                         AZ-b     |
   |  Public 10.0.0.0/24     Public 10.0.1.0/24
   |   ALB node + NAT GW      ALB node + NAT GW      <- alb-sg: 80 from 0.0.0.0/0
   |        |                      |
   |  Private 10.0.10.0/24   Private 10.0.11.0/24
   |   EC2 (Nginx, ASG)       EC2 (Nginx, ASG)       <- web-sg: 80 from alb-sg only
   |        |                      |
   |  DB 10.0.20.0/24        DB 10.0.21.0/24
   |   RDS PostgreSQL primary <-> Multi-AZ standby   <- db-sg: 5432 from web-sg only
   +----------------------------------------+
```

| Layer | Resources |
|-------|-----------|
| Network | VPC, IGW, 2 public + 2 private (web) + 2 private (db) subnets, one NAT Gateway + EIP per AZ, one private route table per AZ |
| Web tier | Launch template (Amazon Linux 2023, IMDSv2, encrypted EBS, Nginx via user data), Auto Scaling Group in private subnets, IAM role with `AmazonSSMManagedInstanceCore` |
| Load balancing | Internet-facing ALB in public subnets, HTTP:80 listener, target group with `/` health check on port 80 |
| Database | RDS PostgreSQL, **Multi-AZ**, `publicly_accessible = false`, encrypted, in dedicated DB subnets |
| Security | `alb-sg`, `web-sg`, `db-sg` with least-privilege rules; no SSH rule anywhere |

## File layout

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform/provider versions, provider config, default tags |
| `variables.tf` | All inputs with defaults |
| `network.tf` | VPC, subnets, IGW, NAT Gateways, route tables |
| `security_groups.tf` | `alb-sg`, `web-sg`, `db-sg` |
| `iam.tf` | EC2 role, SSM policy attachment, instance profile |
| `alb.tf` | ALB, target group, listener |
| `compute.tf` | Launch template, ASG, scaling policies, CloudWatch alarms |
| `rds.tf` | DB subnet group and RDS instance |
| `user_data.sh` | Installs Nginx and serves "Hello World" |
| `outputs.tf` | ALB DNS name, IDs, DB endpoint, secret ARN |

## Design decisions

- **NAT per AZ**: each private subnet routes `0.0.0.0/0` to the NAT Gateway in its own AZ, so an AZ outage does not break egress in the other.
- **Separate DB subnets**: the scenario asks for the database in separate private subnets, so the data tier has its own subnets and a route table with no internet route.
- **No SSH**: `web-sg` has no port 22 rule at all (equivalent to denying `0.0.0.0/0`). Shell access is via AWS Systems Manager Session Manager.
- **Scaling**: simple scaling policies driven by CloudWatch alarms: +1 instance when average CPU > 70% for 5 minutes, -1 when < 30% for 5 minutes (thresholds are variables).
- **IMDSv2 required**, EBS and RDS storage encrypted.
- **Egress on web-sg** is limited to 443/80 (via NAT, for package repos and SSM) and 5432 to `db-sg`.

## Secrets management

No database credentials are hardcoded in the Terraform code, `terraform.tfvars`, or user data.

- `manage_master_user_password = true` makes RDS generate the master password and store it in **AWS Secrets Manager** (the ARN is exposed as the `db_master_secret_arn` output). Only the username (`appadmin`) is a variable.
- The password is never passed through Terraform variables. Note that the secret's ARN, not its value, is stored in Terraform state.
- Retrieve it when needed:
  ```bash
  aws secretsmanager get-secret-value \
    --secret-id "$(terraform output -raw db_master_secret_arn)" \
    --query SecretString --output text
  ```
- Applications should read the secret at runtime. To enable this, attach a policy to the web role allowing `secretsmanager:GetSecretValue` on that secret ARN only (not included, since the assignment's app does not use the database).
- The secret supports automatic rotation managed by RDS.
- Never store AWS credentials on instances. The EC2 role provides temporary credentials.

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure` or SSO) with permissions for VPC, EC2, ELB, Auto Scaling, RDS, IAM, CloudWatch and Secrets Manager.

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # optional; defaults work
terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

RDS Multi-AZ takes roughly 10-20 minutes to create.

## Verify

```bash
ALB=$(terraform output -raw alb_dns_name)
curl -i http://$ALB          # expect 200 and "Hello World"
for i in 1 2 3 4; do curl -s http://$ALB | grep "Served by"; done   # alternates instances/AZs
```

Also check in the console: both targets healthy in the target group, instances have no public IPs, RDS shows Multi-AZ = Yes and Publicly accessible = No.

Optional scaling test via SSM Session Manager on an instance:
```bash
sudo dnf install -y stress-ng && stress-ng --cpu 0 --timeout 600
```
The `cpu-high` alarm should trigger a scale-out after about 5 minutes.

## Cost warning

Roughly: 2 NAT Gateways, an ALB, 2x t3.micro, and a Multi-AZ db.t3.micro cost a few dollars per day. Destroy when finished.

## Destroy

```bash
terraform destroy
```

`db_skip_final_snapshot` defaults to `true` so destroy works cleanly for this exercise; set it to `false` for real environments.

## Possible improvements (out of scope)

- HTTPS listener with ACM certificate and HTTP-to-HTTPS redirect
- Remote state (S3 + DynamoDB/lockfile) and splitting into modules
- WAF on the ALB, VPC flow logs, VPC endpoints for SSM/S3 to reduce NAT traffic
- Target-tracking scaling policy instead of simple scaling
