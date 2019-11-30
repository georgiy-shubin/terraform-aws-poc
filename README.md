## Prove of Concept. Managing Amazon Web Services with Terraform

### Followin AWS Services reflected in the POC:
1.  Network: VPC, Internet Gateway, Route Table, Route, Subnet, Security Group
2.  Route53: Domains, Hosted Zone, Delegation Set
3.  Compute: EC2 Instance, Key Pair
4.  Storage: Amazon S3, Static Web Hosting

### Terraform technics used:
1.  Data Sources
2.  Dynamic resource allocation
3.  Expressions
4.  Provisioners

### The current POC cosists of two parts:
1.  Creating a Jenkins instance in AWS Cloud usring Terraform
2.  Deploying a website usring Jenkins