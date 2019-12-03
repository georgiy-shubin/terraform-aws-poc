## Prove of Concept. Managing Amazon Web Services with Terraform

### Following AWS Services reflected in the POC:
1.  **Network:** VPC, Internet Gateway, Route, Route Table, Subnet, Security Group
2.  **Route 53:** Delegation Set, Domains, Hosted Zone
3.  **IAM**: Role, Policy, Instance Profile
4.  **Compute:** Key Pair, EC2 Instance
5.  **Storage:** Amazon S3, Static Web Hosting

### Terraform technics used:
1.  Data Sources
2.  Dynamic resource allocation
3.  Expressions
4.  Provisioners


### The current POC consists of two parts:
1.  Creating a Jenkins instance in AWS Cloud using Terraform
2.  Deploying a website using Jenkins