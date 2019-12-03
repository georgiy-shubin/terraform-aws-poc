## Prove of Concept. Managing Amazon Web Services with Terraform

### Following AWS Services reflected in the POC:
1.  **Network:** VPC, Internet Gateway, Route Table, Route, Subnet, Security Group
2.  **IAM**: Role, Policy, Instance Profile
3.  **Route53:** Domains, Hosted Zone, Delegation Set
4.  **Compute:** EC2 Instance, Key Pair
5.  **Storage:** Amazon S3, Static Web Hosting

### Terraform technics used:
1.  Data Sources
2.  Dynamic resource allocation
3.  Expressions
4.  Provisioners


### The current POC consists of two parts:
1.  Creating a Jenkins instance in AWS Cloud using Terraform
2.  Deploying a website using Jenkins