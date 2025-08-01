# CloudFront for Static Website Hosting

This guide provides detailed instructions for setting up Amazon CloudFront to deliver your static website content with improved performance and security.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Setting Up CloudFront with S3 (Console)](#setting-up-cloudfront-with-s3-console)
- [Setting Up CloudFront with S3 (AWS CLI)](#setting-up-cloudfront-with-s3-aws-cli)
- [Setting Up CloudFront with EC2 (Console)](#setting-up-cloudfront-with-ec2-console)
- [Setting Up CloudFront with EC2 (AWS CLI)](#setting-up-cloudfront-with-ec2-aws-cli)
- [Custom Domain Configuration](#custom-domain-configuration)
- [Security Best Practices](#security-best-practices)
- [Performance Optimization](#performance-optimization)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)

## Overview

Amazon CloudFront is a content delivery network (CDN) service that:
- Delivers your content through a worldwide network of data centers (edge locations)
- Provides low latency and high transfer speeds
- Integrates with other AWS services like S3, EC2, and AWS Shield
- Offers advanced security features including HTTPS, field-level encryption, and AWS WAF integration

## Prerequisites

- An AWS account
- A static website hosted on either:
  - Amazon S3 bucket configured for static website hosting, or
  - Amazon EC2 instance running a web server
- AWS CLI installed and configured (for CLI instructions)
- Basic understanding of DNS if using a custom domain

## Setting Up CloudFront with S3 (Console)

### Step 1: Prepare Your S3 Bucket

1. Ensure your S3 bucket is properly configured for static website hosting:
   - Navigate to the S3 console
   - Select your bucket
   - Go to the "Properties" tab
   - Confirm "Static website hosting" is enabled
   - Note the bucket website endpoint

2. Verify your bucket policy allows public read access:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "PublicReadGetObject",
               "Effect": "Allow",
               "Principal": "*",
               "Action": "s3:GetObject",
               "Resource": "arn:aws:s3:::your-bucket-name/*"
           }
       ]
   }
   ```

### Step 2: Create a CloudFront Distribution

1. Navigate to the CloudFront console
2. Click "Create Distribution"
3. choose a name for your Distribution
4. you can leave Description as opional
5. from the type select ```single website```
6. 
7. Under "Origin Domain", select your S3 bucket website endpoint
8. For "Origin Path", leave empty if your content is at the root
9. For "Origin ID", keep the default or provide a meaningful name
10. Under "Origin Access", select "Public"
11. For "Default Cache Behavior Settings":
   - Viewer Protocol Policy: Redirect HTTP to HTTPS
   - Allowed HTTP Methods: GET, HEAD (for static sites)
   - Cache Policy: Select "CachingOptimized" for static content
   - Origin Request Policy: Select "CORS-S3Origin"
11. For "Distribution Settings":
   - Price Class: Choose based on your geographic needs
   - AWS WAF Web ACL: Select if you have one configured
   - Alternate Domain Names (CNAMEs): Add your custom domain if applicable
   - SSL Certificate: Select "Default CloudFront Certificate" or use a custom certificate
   - Default Root Object: Enter "index.html"
11. Click "Create Distribution"

### Step 3: Wait for Deployment

1. Wait for the distribution status to change from "In Progress" to "Deployed"
2. This typically takes 15-30 minutes

### Step 4: Test Your CloudFront Distribution

1. Once deployed, note the "Distribution Domain Name" (e.g., d1234abcdef8.cloudfront.net)
2. Visit this URL in your browser to verify your website is being served through CloudFront

## Setting Up CloudFront with S3 (AWS CLI)

### Step 1: Create a CloudFront Distribution Configuration File

Create a file named `distribution-config.json` with the following content:

```json
{
  "CallerReference": "cli-example-1",
  "Comment": "Static website distribution",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-Website-your-bucket-name.s3-website-region.amazonaws.com",
        "DomainName": "your-bucket-name.s3-website-region.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          },
          "OriginReadTimeout": 30,
          "OriginKeepaliveTimeout": 5
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-Website-your-bucket-name.s3-website-region.amazonaws.com",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "MinTTL": 0,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      },
      "Headers": {
        "Quantity": 0
      },
      "QueryStringCacheKeys": {
        "Quantity": 0
      }
    }
  },
  "PriceClass": "PriceClass_100",
  "Enabled": true
}
```

Replace `your-bucket-name` and `region` with your actual S3 bucket name and region.

### Step 2: Create the CloudFront Distribution

```bash
aws cloudfront create-distribution --distribution-config file://distribution-config.json
```

### Step 3: Get Distribution Details

```bash
aws cloudfront get-distribution --id <distribution-id>
```

Replace `<distribution-id>` with the ID returned from the create-distribution command.

### Step 4: Wait for Deployment

Check the status of your distribution:

```bash
aws cloudfront get-distribution --id <distribution-id> --query 'Distribution.Status'
```

Wait until the status changes from "InProgress" to "Deployed".

## Setting Up CloudFront with EC2 (Console)

### Step 1: Prepare Your EC2 Instance

1. Ensure your EC2 instance is running and your web server (Apache, Nginx, etc.) is properly configured
2. Make sure your security group allows inbound HTTP (port 80) and HTTPS (port 443) traffic
3. Note your EC2 instance's public DNS or IP address

### Step 2: Create a CloudFront Distribution

1. Navigate to the CloudFront console
2. Click "Create Distribution"
3. Under "Origin Domain", enter your EC2 instance's public DNS or IP address
4. For "Origin Path", leave empty if your content is at the root
5. For "Origin ID", keep the default or provide a meaningful name
6. For "Default Cache Behavior Settings":
   - Viewer Protocol Policy: Redirect HTTP to HTTPS
   - Allowed HTTP Methods: Choose based on your needs (GET, HEAD for static content)
   - Cache Policy: Select "CachingOptimized" for static content
   - Origin Request Policy: Select "AllViewer"
7. For "Distribution Settings":
   - Price Class: Choose based on your geographic needs
   - AWS WAF Web ACL: Select if you have one configured
   - Alternate Domain Names (CNAMEs): Add your custom domain if applicable
   - SSL Certificate: Select "Default CloudFront Certificate" or use a custom certificate
   - Default Root Object: Enter "index.html"
8. Click "Create Distribution"

### Step 3: Wait for Deployment

1. Wait for the distribution status to change from "In Progress" to "Deployed"
2. This typically takes 15-30 minutes

### Step 4: Test Your CloudFront Distribution

1. Once deployed, note the "Distribution Domain Name" (e.g., d1234abcdef8.cloudfront.net)
2. Visit this URL in your browser to verify your website is being served through CloudFront

## Setting Up CloudFront with EC2 (AWS CLI)

### Step 1: Create a CloudFront Distribution Configuration File

Create a file named `ec2-distribution-config.json` with the following content:

```json
{
  "CallerReference": "cli-example-ec2-1",
  "Comment": "EC2 static website distribution",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "EC2-Origin",
        "DomainName": "ec2-xx-xx-xx-xx.compute-1.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          },
          "OriginReadTimeout": 30,
          "OriginKeepaliveTimeout": 5
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "EC2-Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "MinTTL": 0,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      },
      "Headers": {
        "Quantity": 0
      },
      "QueryStringCacheKeys": {
        "Quantity": 0
      }
    }
  },
  "PriceClass": "PriceClass_100",
  "Enabled": true
}
```

Replace `ec2-xx-xx-xx-xx.compute-1.amazonaws.com` with your actual EC2 public DNS.

### Step 2: Create the CloudFront Distribution

```bash
aws cloudfront create-distribution --distribution-config file://ec2-distribution-config.json
```

### Step 3: Get Distribution Details

```bash
aws cloudfront get-distribution --id <distribution-id>
```

Replace `<distribution-id>` with the ID returned from the create-distribution command.

### Step 4: Wait for Deployment

Check the status of your distribution:

```bash
aws cloudfront get-distribution --id <distribution-id> --query 'Distribution.Status'
```

Wait until the status changes from "InProgress" to "Deployed".

## Custom Domain Configuration

### Step 1: Obtain an SSL Certificate (if using a custom domain)

1. Navigate to AWS Certificate Manager (ACM)
2. Click "Request a certificate"
3. Select "Request a public certificate"
4. Enter your domain name(s) (e.g., example.com, www.example.com)
5. Select "DNS validation" or "Email validation"
6. Follow the validation process to verify domain ownership

### Step 2: Update Your CloudFront Distribution

#### Using the Console:
1. Navigate to the CloudFront console
2. Select your distribution
3. Click the "Edit" button
4. Under "Alternate Domain Names (CNAMEs)", add your custom domain
5. Under "SSL Certificate", select "Custom SSL Certificate" and choose your ACM certificate
6. Click "Save changes"

#### Using the AWS CLI:
1. Get the current distribution configuration:
```bash
aws cloudfront get-distribution-config --id <distribution-id> --output json > dist-config.json
```

2. Edit the `dist-config.json` file to add your custom domain and certificate:
```json
{
  "Aliases": {
    "Quantity": 1,
    "Items": ["www.example.com"]
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "arn:aws:acm:us-east-1:123456789012:certificate/abcdef12-3456-7890-abcd-ef1234567890",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  }
}
```

3. Update the distribution (remove the ETag field and rename it to IfMatch):
```bash
aws cloudfront update-distribution --id <distribution-id> --if-match <etag-value> --distribution-config file://dist-config.json
```

### Step 3: Create DNS Records

1. Navigate to your DNS provider or Route 53
2. Create a CNAME record pointing your domain to your CloudFront distribution domain name:
   - Record type: CNAME
   - Name: www (or subdomain of your choice)
   - Value: your-distribution-id.cloudfront.net
   - TTL: 300 seconds (or as desired)

If using Route 53 with an Alias record:
1. Navigate to the Route 53 console
2. Select your hosted zone
3. Click "Create record"
4. Enter your subdomain (or leave blank for apex domain)
5. Select "A - Routes traffic to an IPv4 address and some AWS resources"
6. Enable "Alias"
7. Select "Alias to CloudFront distribution" and choose your distribution
8. Click "Create records"

## Security Best Practices

### Enable HTTPS

1. Set "Viewer Protocol Policy" to "Redirect HTTP to HTTPS"
2. Use TLSv1.2 or later for origin connections

### Implement AWS WAF

1. Navigate to the AWS WAF console
2. Create a Web ACL with appropriate rules
3. Associate the Web ACL with your CloudFront distribution

### Restrict Geographic Access (Geo-Restriction)

#### Using the Console:
1. Edit your distribution
2. Under "Restrictions", click "Edit"
3. Choose "Whitelist" or "Blacklist"
4. Select the countries to allow or block
5. Click "Save changes"

#### Using the AWS CLI:
```bash
aws cloudfront get-distribution-config --id <distribution-id> --output json > dist-config.json
```

Edit the file to add restrictions:
```json
"Restrictions": {
  "GeoRestriction": {
    "RestrictionType": "whitelist",
    "Quantity": 2,
    "Items": ["US", "CA"]
  }
}
```

Update the distribution:
```bash
aws cloudfront update-distribution --id <distribution-id> --if-match <etag-value> --distribution-config file://dist-config.json
```

### Implement Origin Access Identity (for S3 origins)

#### Using the Console:
1. Edit your distribution
2. Under "Origin Settings", click "Edit"
3. For "Origin Access", select "Origin access control settings (recommended)"
4. Create a new origin access control setting
5. Update your S3 bucket policy to allow access only from this OAC

#### Using the AWS CLI:
1. Create an Origin Access Control:
```bash
aws cloudfront create-origin-access-control --origin-access-control-config file://oac-config.json
```

Where `oac-config.json` contains:
```json
{
  "Name": "S3 OAC for my-bucket",
  "Description": "OAC for S3 static website",
  "SigningProtocol": "sigv4",
  "SigningBehavior": "always",
  "OriginAccessControlOriginType": "s3"
}
```

2. Update your distribution to use the OAC
3. Update your S3 bucket policy

## Performance Optimization

### Configure Cache Behaviors

1. Set appropriate TTL values:
   - Minimum TTL: 0 seconds
   - Default TTL: 86400 seconds (1 day)
   - Maximum TTL: 31536000 seconds (1 year)

2. Enable compression:
   - Set "Compress Objects Automatically" to "Yes"

### Optimize Origin Response

1. Configure proper caching headers on your origin
2. For S3, set metadata properties for objects
3. For EC2, configure your web server to send appropriate Cache-Control headers

### Use Cache Policies

1. Create a custom cache policy or use AWS managed policies
2. Configure which headers, cookies, and query strings to include in the cache key

## Monitoring and Troubleshooting

### Enable CloudFront Logging

#### Using the Console:
1. Edit your distribution
2. Under "Logging", click "Edit"
3. Enable logging
4. Specify the S3 bucket for logs
5. Optionally, specify a prefix
6. Click "Save changes"

#### Using the AWS CLI:
```bash
aws cloudfront get-distribution-config --id <distribution-id> --output json > dist-config.json
```

Edit the file to enable logging:
```json
"Logging": {
  "Enabled": true,
  "IncludeCookies": false,
  "Bucket": "my-logs-bucket.s3.amazonaws.com",
  "Prefix": "cloudfront-logs/"
}
```

Update the distribution:
```bash
aws cloudfront update-distribution --id <distribution-id> --if-match <etag-value> --distribution-config file://dist-config.json
```

### Set Up CloudWatch Alarms

1. Navigate to the CloudWatch console
2. Create alarms for metrics like:
   - 5xxErrorRate
   - 4xxErrorRate
   - TotalErrorRate
   - BytesDownloaded

### Troubleshooting Common Issues

1. **Content not updating**: Check the TTL settings and consider creating an invalidation
2. **Access Denied errors**: Verify origin permissions and security settings
3. **SSL/TLS errors**: Check certificate validity and configuration
4. **Slow performance**: Review cache hit ratio and origin response times

To create an invalidation:
```bash
aws cloudfront create-invalidation --distribution-id <distribution-id> --paths "/*"
```

## Conclusion

CloudFront provides a powerful way to deliver your static website content with improved performance, security, and reliability. By following this guide, you've learned how to set up CloudFront with both S3 and EC2 origins, configure custom domains, implement security best practices, optimize performance, and monitor your distribution.

For more information, refer to the [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/).
