# Static Website Hosting on AWS - Project Summary

This project demonstrates how to host static websites on AWS using two different approaches: Amazon S3 and Amazon EC2. It includes sample files, deployment scripts, and a real-world project scenario.

## Directory Structure

```
AWS-storage/
├── README.md                           # Main documentation
├── SUMMARY.md                          # This summary file
├── sample-website/                     # Sample static website files
│   ├── index.html                      # Homepage
│   ├── error.html                      # Error page
│   ├── css/                            # CSS stylesheets
│   │   └── styles.css
│   ├── js/                             # JavaScript files
│   │   └── script.js
│   └── images/                         # Image directory
├── deploy-to-s3.sh                     # S3 deployment script
├── deploy-to-ec2.sh                    # EC2 deployment script
├── cloudformation-templates/           # CloudFormation templates
│   ├── s3-static-website.yaml          # S3 website template
│   ├── ec2-static-website.yaml         # EC2 website template
│   └── hybrid-static-website.yaml      # Hybrid solution template
└── project-travelexplore/              # Real-world project example
    ├── README.md                       # Project documentation
    ├── architecture-diagram.txt        # Architecture diagram (text)
    ├── index.html                      # Project demo page
    ├── replication-trust-policy.json   # S3 replication IAM trust policy
    ├── replication-policy.json         # S3 replication IAM policy
    ├── replication-config-europe.json  # S3 replication config for Europe
    ├── replication-config-asia.json    # S3 replication config for Asia
    ├── web-server-setup.sh             # EC2 web server setup script
    ├── cloudfront-config.json          # CloudFront distribution config
    ├── route53-records.json            # Route 53 DNS records
    └── monitor-resources.sh            # Resource monitoring script
```

## Key Components

### 1. Sample Website

A responsive travel agency website template with:
- HTML5 semantic structure
- CSS3 styling with responsive design
- JavaScript for interactivity
- Error page for 404 handling

### 2. Deployment Scripts

- `deploy-to-s3.sh`: Automates the process of creating an S3 bucket, configuring it for static website hosting, setting permissions, and uploading files
- `deploy-to-ec2.sh`: Automates the process of connecting to an EC2 instance, installing and configuring Apache, and deploying website files

### 3. CloudFormation Templates

- `s3-static-website.yaml`: Creates an S3 bucket configured for static website hosting with optional CloudFront distribution
- `ec2-static-website.yaml`: Launches an EC2 instance with Apache installed and configured
- `hybrid-static-website.yaml`: Creates both S3 and EC2 resources with CloudFront distribution that routes requests appropriately

### 4. TravelExplore Project

A real-world scenario for a global travel agency that needs to deliver content worldwide with minimal latency:

- **Multi-Region Architecture**: Resources deployed in North America, Europe, and Asia
- **Hybrid Approach**: S3 for static assets, EC2 for dynamic content
- **Global Content Delivery**: CloudFront distribution with appropriate cache behaviors
- **Intelligent Routing**: Route 53 with health checks and latency-based routing
- **Monitoring**: Script to check resource health and performance

## Hosting Approaches Compared

| Feature | S3 Hosting | EC2 Hosting |
|---------|------------|-------------|
| Server Management | None (serverless) | Full control required |
| Scalability | Automatic | Manual or with Auto Scaling |
| Cost | Pay for storage and requests | Pay for compute time |
| Dynamic Content | Not supported natively | Fully supported |
| Security | S3 policies, CloudFront | Security groups, NACLs |
| Performance | Good with CloudFront | Depends on instance type |
| Maintenance | Minimal | OS and web server updates |

## Use Cases

1. **S3 Hosting**: Ideal for static content, marketing sites, documentation
2. **EC2 Hosting**: Better for dynamic content, applications requiring server-side processing
3. **Hybrid Approach**: Best for complex applications with both static and dynamic components

## Production Considerations

- **Custom Domain**: Use Route 53 to map your domain to your website
- **HTTPS**: Use ACM certificates with CloudFront or on EC2
- **Monitoring**: Set up CloudWatch alarms for performance and availability
- **Backup**: Enable versioning for S3, create AMI snapshots for EC2
- **Security**: Implement WAF, security groups, and least privilege access

## Getting Started

1. Review the `README.md` file for detailed instructions
2. Explore the sample website files in the `sample-website` directory
3. Use the deployment scripts to deploy to your AWS account (modify as needed)
4. Study the TravelExplore project for a comprehensive real-world example

## Next Steps

- Implement CI/CD pipelines for automated deployments
- Add authentication and authorization for protected content
- Implement a content management system for easier updates
- Set up monitoring and alerting for your website
- Configure backup and disaster recovery procedures
