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
![7f22499d-8563-4337-8eed-6e6a51fb250e-0](https://github.com/user-attachments/assets/e31aea78-9c74-4991-92b0-0d36f87648e4)


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

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Python 3.11
- AWS Bedrock model access enabled

### Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/Yashmaini30/CopyGuard
   cd CopyGuard
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values as directed
   ```

3. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access the application**
   - Frontend: CloudFront distribution URL
   - API: API Gateway endpoint URL

### API Usage

```bash
curl -X POST https://your-api-endpoint/detect \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-secret-key" \
  -d '{
    "code": "def fibonacci(n): return n if n <= 1 else fibonacci(n-1) + fibonacci(n-2)"
  }'
```

**Response:**
```json
{
  "result": {
    "label": "Human-written",
    "confidence": 85,
    "raw": "This code appears to be human-written with 85% confidence..."
  },
  "s3_key": "results/2024-01-15T10:30:00.000Z_abc123.json"
}
```


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


