# CloudFormation Infrastructure Setup

Complete AWS infrastructure setup using CloudFormation templates for VPC, EC2 management server, and EKS cluster.

## Infrastructure Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS INFRASTRUCTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                      VPC                                │    │
│  │                 192.168.0.0/16                          │    │
│  │                                                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │   Public    │  │   Private   │  │   Private   │      │    │
│  │  │  Subnets    │  │ App Subnets │  │ DB Subnets  │      │    │
│  │  │             │  │             │  │             │      │    │
│  │  │ NAT Gateway │  │ EKS Nodes   │  │ RDS MySQL   │      │    │
│  │  │ ALB         │  │ EC2 Mgmt    │  │             │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   EKS Cluster                           │    │
│  │                                                         │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │    │
│  │  │ Control     │  │   Worker    │  │   Worker    │      │    │
│  │  │   Plane     │  │   Nodes     │  │   Nodes     │      │    │
│  │  │             │  │   (AZ-1)    │  │   (AZ-2)    │      │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```


## Deployment Instructions

### **Step 1: Deploy VPC Stack**
```bash
# Deploy VPC infrastructure
aws cloudformation create-stack \
  --stack-name taskapi-vpc \
  --template-body file://01-vpc-stack.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=TaskAPI \
  --region ap-south-1

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name taskapi-vpc \
  --region ap-south-1
```

### **Step 2: Deploy EC2 Management Server**
```bash
# Deploy management server
aws cloudformation create-stack \
  --stack-name taskapi-ec2 \
  --template-body file://02-ec2-stack.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=TaskAPI \
    ParameterKey=KeyPairName,ParameterValue=your-key-pair \
    ParameterKey=InstanceType,ParameterValue=t3a.medium \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-south-1

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name taskapi-ec2 \
  --region ap-south-1
```

### **Step 3: Deploy EKS Cluster**
```bash
# Deploy EKS cluster
aws cloudformation create-stack \
  --stack-name taskapi-eks \
  --template-body file://03-eks-stack.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=TaskAPI \
    ParameterKey=NodeInstanceType,ParameterValue=t3.medium \
    ParameterKey=NodeGroupDesiredSize,ParameterValue=2 \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-south-1

# Wait for completion (takes 15-20 minutes)
aws cloudformation wait stack-create-complete \
  --stack-name taskapi-eks \
  --region ap-south-1
```

### **Step 4: Configure kubectl**
```bash
# SSH to management server
ssh -i your-key.pem ec2-user@<management-server-ip>

# Configure kubectl
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name TaskAPI-EKS-Cluster

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

## Infrastructure Validation

### **Verify VPC Resources**
```bash
# Check VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=TaskAPI-VPC" \
  --region ap-south-1

# Check subnets
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=TaskAPI-*" \
  --region ap-south-1

# Check NAT Gateways
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Name,Values=TaskAPI-*" \
  --region ap-south-1
```

### **Verify EKS Cluster**
```bash
# Check cluster status
aws eks describe-cluster \
  --name TaskAPI-EKS-Cluster \
  --region ap-south-1

# Check node group
aws eks describe-nodegroup \
  --cluster-name TaskAPI-EKS-Cluster \
  --nodegroup-name TaskAPI-NodeGroup \
  --region ap-south-1
```

### **Cost Estimation**
- **VPC**: Free (NAT Gateways ~$45/month)
- **EC2 Management**: t3a.medium ~$30/month
- **EKS Cluster**: $73/month (control plane)
- **EKS Nodes**: 2 x t3.medium ~$60/month
- **Total**: ~$208/month

This infrastructure provides a production-ready foundation for deploying the Task Management API with proper security, scalability, and high availability.
