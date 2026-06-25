# terraform-aws-vpc

Terraform module to create a production-ready AWS VPC with public, private, and database subnets across two availability zones, along with an Internet Gateway, NAT Gateway, route tables, and optional VPC peering to the default VPC.

## Architecture

```
                        Internet
                           |
                    Internet Gateway
                           |
              ┌────────────┴────────────┐
              │                         │
       Public Subnet 1a          Public Subnet 1b
       (map_public_ip=true)      (map_public_ip=true)
              │
         NAT Gateway (EIP)
              │
       ┌──────┴──────┐
       │             │
  Private 1a    Private 1b
  Database 1a   Database 1b
```

## Features

- VPC with DNS hostnames enabled
- Internet Gateway for public subnets
- NAT Gateway (single, in first public subnet) for private and database subnets
- Public, private, and database subnets across 2 AZs (auto-detected)
- Separate route tables for each subnet tier
- Optional VPC peering with the AWS default VPC
- Consistent tagging via `common_tags` locals (`Project`, `Environment`, `Terraform`, `Name`)

## Usage

```hcl
module "vpc" {
  source = "github.com/sivakmrreddy/terraform-aws-vpc"

  project     = "roboshop"
  environment = "dev"

  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]

  is_peering_required = false
}
```

### With VPC Peering

```hcl
module "vpc" {
  source = "github.com/sivakmrreddy/terraform-aws-vpc"

  project     = "roboshop"
  environment = "dev"

  vpc_cidr = "10.0.0.0/16"

  is_peering_required = true

  vpc_peering_tags = {
    Name = "roboshop-dev-to-default"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Environment name (e.g. dev, prod) | `string` | — | yes |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `public_subnet_cidrs` | List of CIDR blocks for public subnets (one per AZ) | `list` | `["10.0.1.0/24","10.0.2.0/24"]` | no |
| `private_subnet_cidrs` | List of CIDR blocks for private subnets (one per AZ) | `list` | `["10.0.11.0/24","10.0.12.0/24"]` | no |
| `database_subnet_cidrs` | List of CIDR blocks for database subnets (one per AZ) | `list` | `["10.0.21.0/24","10.0.22.0/24"]` | no |
| `is_peering_required` | Whether to create a VPC peering connection with the default VPC | `bool` | `false` | no |
| `vpc_tags` | Extra tags to merge onto the VPC resource | `map` | `{}` | no |
| `igw_tags` | Extra tags to merge onto the Internet Gateway | `map` | `{}` | no |
| `public_subnet_tags` | Extra tags to merge onto public subnets | `map` | `{}` | no |
| `private_subnet_tags` | Extra tags to merge onto private subnets | `map` | `{}` | no |
| `database_subnet_tags` | Extra tags to merge onto database subnets | `map` | `{}` | no |
| `public_route_table_tags` | Extra tags to merge onto the public route table | `map` | `{}` | no |
| `private_route_table_tags` | Extra tags to merge onto the private route table | `map` | `{}` | no |
| `database_route_table_tags` | Extra tags to merge onto the database route table | `map` | `{}` | no |
| `eip_tags` | Extra tags to merge onto the NAT Elastic IP | `map` | `{}` | no |
| `nat_gateway_tags` | Extra tags to merge onto the NAT Gateway | `map` | `{}` | no |
| `vpc_peering_tags` | Extra tags to merge onto the VPC peering connection | `map` | `{}` | no |

## Outputs

This module currently has no active outputs. The `azs_info` output is commented out. You can reference resources directly via the module's internal resource addresses when used with `terraform_remote_state` or data sources.

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_vpc.main` | The VPC |
| `aws_internet_gateway.main` | Internet Gateway attached to the VPC |
| `aws_subnet.public[*]` | Public subnets (one per CIDR provided) |
| `aws_subnet.private[*]` | Private subnets (one per CIDR provided) |
| `aws_subnet.database[*]` | Database subnets (one per CIDR provided) |
| `aws_route_table.public` | Route table for public subnets (routes to IGW) |
| `aws_route_table.private` | Route table for private subnets (routes to NAT GW) |
| `aws_route_table.database` | Route table for database subnets (routes to NAT GW) |
| `aws_eip.nat` | Elastic IP for the NAT Gateway |
| `aws_nat_gateway.main` | NAT Gateway in the first public subnet |
| `aws_vpc_peering_connection.default` | VPC peering to default VPC (when `is_peering_required = true`) |
| `aws_route.public_peering` | Peering route in public route table (when peering enabled) |

## Naming Convention

Resources are named using the pattern `<project>-<environment>-<tier>-<az-suffix>`.  
Example: `roboshop-dev-public-1a`, `roboshop-dev-private-1b`, `roboshop-dev-nat`.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0 |
| AWS Provider | >= 4.0 |

## Notes

- The module always selects the first two available AZs in the region automatically.
- The NAT Gateway is deployed in the first public subnet only. All private and database subnets share it.
- VPC peering (`is_peering_required = true`) peers with the region's **default** VPC and auto-accepts the connection.