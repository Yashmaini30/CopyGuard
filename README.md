# 🛡️ CopyGuard

Production-ready serverless platform for AI-powered code analysis using AWS Bedrock and DevOps best practices

## 🚀 Overview

A sophisticated CopyGuard platform that analyzes code snippets to detect AI-generated content using Amazon Bedrock's Claude v2 model. Built with enterprise-grade DevOps practices including Infrastructure as Code, comprehensive monitoring, and production-ready security.

## 🎯 Key Features

- 🧠 **AI-Powered Analysis**: Leverages Amazon Bedrock's Claude v2 for intelligent code detection
- ☁️ **Serverless Architecture**: Cost-effective, auto-scaling infrastructure
- 🔒 **Enterprise Security**: IAM roles, API authentication, and secure access controls
- 📊 **Production Monitoring**: CloudWatch metrics, alarms, and Grafana dashboards
- 🌍 **Global Distribution**: CloudFront CDN for optimal performance
- 📈 **Real-time Metrics**: Custom CloudWatch metrics for confidence scores and latency
- 💾 **Persistent Storage**: S3 integration for analysis results and audit trails

## 🏗️ Architecture


## 🛠️ Technology Stack

### Infrastructure
- **AWS Lambda**: Serverless compute with Python 3.11 runtime
- **Amazon Bedrock**: GenAI foundation models (Claude v2)
- **API Gateway v2**: HTTP API with CORS support
- **CloudFront**: Global CDN with Origin Access Control
- **S3**: Static website hosting and results storage
- **Terraform**: Infrastructure as Code

### Monitoring & Security
- **CloudWatch**: Logging, metrics, and alerting
- **Amazon Managed Grafana**: Advanced dashboards with AWS SSO
- **IAM**: Least-privilege access control
- **API Key Authentication**: Secure endpoint access

### Development
- **Python 3.11**: Lambda runtime with boto3 SDK
- **Regular Expressions**: Advanced response parsing
- **Error Handling**: Production-ready exception management

## 🔧 Key Components

### Lambda Handler Features
- **Intelligent Response Parsing**: Advanced regex patterns for confidence score extraction
- **Multi-pattern Detection**: Handles various AI detection scenarios
- **Custom Metrics**: Real-time CloudWatch metrics for monitoring
- **S3 Integration**: Automatic result storage with timestamps
- **Error Handling**: Comprehensive exception management
- **Performance Tracking**: Latency metrics and optimization

### Terraform Infrastructure
- **Modular Design**: Reusable components and random suffixes
- **Security First**: IAM policies with least privilege
- **Monitoring Built-in**: CloudWatch alarms and log groups
- **Cost Optimized**: Serverless architecture with proper timeouts

## 📊 Monitoring & Observability

### Custom CloudWatch Metrics
- **ConfidenceScore**: AI detection confidence percentage
- **IsAIGenerated**: Binary classification results
- **LatencyMs**: Response time performance
- **Lambda Errors**: Automated error alerting

### Production Features
- **60-day log retention**: Compliance and debugging
- **Error threshold alarms**: Proactive issue detection
- **Grafana dashboards**: Advanced visualization
- **S3 audit trail**: Complete analysis history

## 🚀 Quick Start


## 💰 Cost Analysis

### Estimated Monthly Costs (1,000 requests)
- **Lambda**: ~$0.20 (compute time)
- **API Gateway**: ~$3.50 (per million requests)
- **Bedrock**: ~$15.00 (Claude v2 model inference)
- **S3**: ~$0.05 (storage and requests)
- **CloudWatch**: ~$2.00 (logs and metrics)
- **CloudFront**: ~$1.00 (data transfer)
- **Total**: ~$22/month for 1K requests

### Scaling Economics
- **10K requests**: ~$180/month
- **100K requests**: ~$1,650/month
- **Cost per request**: ~$0.016

## 🔒 Security Features

### API Security
- API key authentication
- CORS configuration
- Rate limiting capabilities

### AWS Security
- IAM roles with least privilege
- S3 bucket policies
- VPC endpoints (optional)
- CloudTrail logging

### Data Protection
- Encrypted data in transit
- S3 server-side encryption
- No sensitive data in logs

## 📈 Performance Optimization

### Response Time Targets
- **Average latency**: <2 seconds
- **P95 latency**: <5 seconds
- **Timeout**: 30 seconds maximum

### Optimization Techniques
- Connection pooling for AWS services
- Efficient regex patterns
- Minimal cold start impact
- Optimized Bedrock model parameters

## 🔮 Future Enhancements

### Technical Roadmap
- [ ] **Multi-model Support**: GPT-4, Llama 2, Claude 3
- [ ] **Batch Processing**: Analyze multiple files
- [ ] **CI/CD Pipeline**: GitHub Actions deployment
- [ ] **Advanced Analytics**: ML-powered insights
- [ ] **Rate Limiting**: API throttling implementation
- [ ] **Caching Layer**: Redis for frequent requests

### Business Features
- [ ] **User Authentication**: AWS Cognito integration
- [ ] **Usage Analytics**: Detailed reporting dashboard
- [ ] **API Versioning**: Backward compatibility
- [ ] **Webhook Support**: Real-time notifications

## 📝 Project Structure
```
├── lambda/
│   ├── dependency/         # Lambda dependencies
│   ├── code_detector.zip   # Packaged Lambda function
│   ├── handler.py          # Lambda function code
│   └── requirements.txt    # Python dependencies
|
├── .gitignore             # Git ignore rules
├── architecture.html      # Architecture documentation
├── index.html             # Frontend web interface
├── main.tf                # Terraform main configuration
├── outputs.tf             # Terraform output values
├── README.md              # This file
├── script.js              # Frontend JavaScript logic
├── styles.css             # Frontend styling
├── terraform.tfvars       # Terraform variables (local config)
├── terraform.tfvars.example # Example terraform variables
└── variables.tf           # Terraform input variables
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Contact

**Yash Maini** - mainiyash2@.com

**Project Link**: https://github.com/Yashmaini30/CopyGuard

---

⭐ **Star this repository if you found it helpful!**



