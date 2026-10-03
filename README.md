# CloudNet

Terraform configuration that builds a small AWS network in `us-east-1`: a VPC with public and private subnets, plus an Amazon Linux 2023 web server running Apache in the public subnet.

## Architecture

```
                    Internet
                        │
               ┌────────┴────────┐
               │ Internet Gateway│
               └────────┬────────┘
┌───────────────────────┼──────────────────────────────┐
│ VPC 10.0.0.0/16       │                              │
│                       │  public route table          │
│                       │  0.0.0.0/0 → IGW             │
│  ┌────────────────────┴──────┐  ┌──────────────────┐ │
│  │ Public subnet 10.0.1.0/24 │  │ Private subnet   │ │
│  │ (us-east-1a)              │  │ 10.0.2.0/24      │ │
│  │                           │  │ (us-east-1a)     │ │
│  │  EC2 t3.micro web server  │  │                  │ │
│  │  SG: HTTP 80 (any),       │  │  private SG:     │ │
│  │      SSH 22 (one IP)      │──┼─▶ MySQL 3306     │ │
│  └───────────────────────────┘  │  from public SG  │ │
│                                 └──────────────────┘ │
└──────────────────────────────────────────────────────┘
```

The private subnet and its security group are ready for a database later. Nothing runs there yet.

| File | Resources |
|------|-----------|
| `provider.tf` | Terraform and AWS provider versions, S3 remote state backend with DynamoDB locking, AWS provider (`us-east-1`, profile `cloudnet`) |
| `vpc.tf` | `aws_vpc`, `aws_internet_gateway`, public `aws_route_table`, public and private `aws_subnet`, route table association |
| `security.tf` | `cloudnet-public-sg` (HTTP from anywhere, SSH from one IP), `cloudnet-private-sg` (MySQL 3306 from the public SG only) |
| `compute.tf` | Latest Amazon Linux 2023 AMI lookup, `cloudnet-key` key pair, `t3.micro` web server with Apache set up by user data |
| `output.tf` | The web server's public IP and URL |
| `variables.tf` / `terraform.tfvars` | `aws_region` and `environment` variables |

## Prerequisites

- **Terraform** 1.0 or later. The AWS provider is `~> 5.0`, and `.terraform.lock.hcl` pins 5.100.0.
- **AWS CLI** with a profile named `cloudnet`:
  ```bash
  aws configure --profile cloudnet
  ```
- **A remote state backend** you create before running `terraform init`:
  - An S3 bucket to hold the state file
  - A DynamoDB table named `terraform-state-lock` with partition key `LockID` (type String)
  ```bash
  aws s3api create-bucket --bucket <your-bucket-name> --region us-east-1 --profile cloudnet
  aws s3api put-bucket-versioning --bucket <your-bucket-name> \
    --versioning-configuration Status=Enabled --profile cloudnet
  aws dynamodb create-table --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST --region us-east-1 --profile cloudnet
  ```
- **An SSH key pair** in the project root, named `cloudnet_key` and `cloudnet_key.pub`:
  ```bash
  ssh-keygen -t rsa -b 4096 -f cloudnet_key
  ```

## Configuration

Change these before your first deploy:

1. **Backend bucket**: in `provider.tf`, set `bucket` to your own bucket name. S3 bucket names must be unique across all of AWS.
2. **SSH source IP**: in `security.tf`, change the SSH ingress `cidr_blocks` (currently `49.36.64.4/32`) to your public IP followed by `/32`. You can find your IP with `curl https://checkip.amazonaws.com`.

> **Note:** The `aws_region` and `environment` variables in `variables.tf` aren't used by any resource yet. The region is hardcoded as `us-east-1` in `provider.tf`, `vpc.tf` (availability zone), and the backend block, so changing `terraform.tfvars` has no effect for now.

## Usage

```bash
terraform init      # download the provider and connect to the S3 backend
terraform plan      # preview the changes
terraform apply     # create the infrastructure
terraform output    # show the server IP and URL
```

The instance needs a minute or two after `apply` to finish installing Apache. Then:

```bash
curl $(terraform output -raw web_server_url)
# CloudNet: Deployment Successful!

ssh -i cloudnet_key ec2-user@$(terraform output -raw web_server_public_ip)
```

## Outputs

| Name | Description |
|------|-------------|
| `web_server_public_ip` | Public IP address of the web server |
| `web_server_url` | HTTP URL of the web server (`http://<public-ip>`) |

## Teardown

```bash
terraform destroy
```

This doesn't remove the S3 state bucket or the DynamoDB lock table. Delete them yourself if you no longer need them.

## Security notes

- **Never commit the private key `cloudnet_key`.** It's listed in `.gitignore`. Only the `.pub` file is meant to be shared.
- Limit SSH to your own `/32` address. Don't open port 22 to `0.0.0.0/0`.
- The web server uses plain HTTP (port 80) with no TLS.
- State files can contain sensitive values. They live in S3 and are excluded from Git.

## Cost

- `t3.micro` is eligible for the AWS Free Tier on new accounts. Outside the free tier, you pay standard on-demand pricing.
- There is no NAT gateway, which keeps costs down. As a result, anything placed in the private subnet has **no outbound internet access**.
- The S3 and DynamoDB (on-demand) backend costs very little at this scale.

## Project structure

```
cloudnet/
├── provider.tf          # Terraform settings, S3 backend, AWS provider
├── variables.tf         # Input variables (not yet referenced)
├── terraform.tfvars     # Variable values
├── vpc.tf               # VPC, subnets, internet gateway, route table
├── security.tf          # Public and private security groups
├── compute.tf           # AMI lookup, key pair, EC2 web server
├── output.tf            # Outputs
├── cloudnet_key.pub     # SSH public key (private key is gitignored)
├── .terraform.lock.hcl  # Provider version lock
└── .gitignore
```
