# AWS Infrastructure Project Structure

```
aws-cli/
├── cli-scripts/
│   ├── 01-create-vpc.sh
│   ├── 02-create-subnets.sh
│   ├── 03-create-igw.sh
│   ├── 04-create-route-table.sh
│   ├── 05-create-security-group.sh
│   ├── 06-create-ami.sh
│   ├── 07-launch-ec2.sh
│   ├── cleanup.sh
│   └── variables.sh
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── security.tf
│   ├── compute.tf
│   └── terraform.tfvars.example
├── cli-README.md
├── terraform-README.md
└── architecture-diagram.png
```
