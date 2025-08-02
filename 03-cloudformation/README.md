# CloudFormation Infrastructure Setup

Complete AWS infrastructure setup using CloudFormation templates for VPC, EC2 management server, and EKS cluster.

## Infrastructure Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS INFRASTRUCTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      VPC                                │   │
│  │                 192.168.0.0/16                          │   │
│  │                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │   Public    │  │   Private   │  │   Private   │     │   │
│  │  │  Subnets    │  │ App Subnets │  │ DB Subnets  │     │   │
│  │  │             │  │             │  │             │     │   │
│  │  │ NAT Gateway │  │ EKS Nodes   │  │ RDS MySQL   │     │   │
│  │  │ ALB         │  │ EC2 Mgmt    │  │             │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   EKS Cluster                           │   │
│  │                                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │ Control     │  │   Worker    │  │   Worker    │     │   │
│  │  │   Plane     │  │   Nodes     │  │   Nodes     │     │   │
│  │  │             │  │   (AZ-1)    │  │   (AZ-2)    │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Stack 1: VPC Infrastructure

### **01-vpc-stack.yaml**
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'VPC Infrastructure for Task Management API'

Parameters:
  EnvironmentName:
    Description: Environment name prefix for resources
    Type: String
    Default: TaskAPI
    
  VpcCIDR:
    Description: CIDR block for VPC
    Type: String
    Default: 192.168.0.0/16
    
  PublicSubnet1CIDR:
    Description: CIDR block for Public Subnet 1
    Type: String
    Default: 192.168.1.0/24
    
  PublicSubnet2CIDR:
    Description: CIDR block for Public Subnet 2
    Type: String
    Default: 192.168.2.0/24
    
  PrivateAppSubnet1CIDR:
    Description: CIDR block for Private App Subnet 1
    Type: String
    Default: 192.168.3.0/24
    
  PrivateAppSubnet2CIDR:
    Description: CIDR block for Private App Subnet 2
    Type: String
    Default: 192.168.4.0/24
    
  PrivateDBSubnet1CIDR:
    Description: CIDR block for Private DB Subnet 1
    Type: String
    Default: 192.168.5.0/24
    
  PrivateDBSubnet2CIDR:
    Description: CIDR block for Private DB Subnet 2
    Type: String
    Default: 192.168.6.0/24

Resources:
  # VPC
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-VPC
        - Key: Environment
          Value: !Ref EnvironmentName

  # Internet Gateway
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-IGW

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  # Public Subnets
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Ref PublicSubnet1CIDR
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Public-Subnet-AZ1
        - Key: kubernetes.io/role/elb
          Value: 1

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Ref PublicSubnet2CIDR
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Public-Subnet-AZ2
        - Key: kubernetes.io/role/elb
          Value: 1

  # Private App Subnets
  PrivateAppSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Ref PrivateAppSubnet1CIDR
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Private-App-Subnet-AZ1
        - Key: kubernetes.io/role/internal-elb
          Value: 1

  PrivateAppSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Ref PrivateAppSubnet2CIDR
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Private-App-Subnet-AZ2
        - Key: kubernetes.io/role/internal-elb
          Value: 1

  # Private DB Subnets
  PrivateDBSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Ref PrivateDBSubnet1CIDR
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Private-DB-Subnet-AZ1

  PrivateDBSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Ref PrivateDBSubnet2CIDR
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Private-DB-Subnet-AZ2

  # NAT Gateways
  NatGateway1EIP:
    Type: AWS::EC2::EIP
    DependsOn: InternetGatewayAttachment
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-NAT-EIP-AZ1

  NatGateway2EIP:
    Type: AWS::EC2::EIP
    DependsOn: InternetGatewayAttachment
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-NAT-EIP-AZ2

  NatGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway1EIP.AllocationId
      SubnetId: !Ref PublicSubnet1
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-NAT-Gateway-AZ1

  NatGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway2EIP.AllocationId
      SubnetId: !Ref PublicSubnet2
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-NAT-Gateway-AZ2

  # Route Tables
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Public-Routes

  DefaultPublicRoute:
    Type: AWS::EC2::Route
    DependsOn: InternetGatewayAttachment
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet1

  PublicSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet2

  PrivateRouteTable1:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Private-Routes-AZ1

  DefaultPrivateRoute1:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway1

  PrivateAppSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      SubnetId: !Ref PrivateAppSubnet1

  PrivateDBSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      SubnetId: !Ref PrivateDBSubnet1

  PrivateRouteTable2:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Private-Routes-AZ2

  DefaultPrivateRoute2:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable2
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway2

  PrivateAppSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable2
      SubnetId: !Ref PrivateAppSubnet2

  PrivateDBSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable2
      SubnetId: !Ref PrivateDBSubnet2

  # Security Groups
  EKSClusterSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for EKS cluster
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
          Description: HTTPS access to EKS API
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-EKS-Cluster-SG

  EKSNodeSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for EKS worker nodes
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          SourceSecurityGroupId: !Ref ManagementSecurityGroup
          Description: SSH from management server
        - IpProtocol: tcp
          FromPort: 1025
          ToPort: 65535
          SourceSecurityGroupId: !Ref EKSClusterSecurityGroup
          Description: All traffic from EKS cluster
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-EKS-Node-SG

  ManagementSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for management server
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
          Description: SSH access
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
          Description: HTTP access
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
          Description: HTTPS access
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Management-SG

  DatabaseSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for RDS MySQL
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 3306
          ToPort: 3306
          SourceSecurityGroupId: !Ref EKSNodeSecurityGroup
          Description: MySQL access from EKS nodes
        - IpProtocol: tcp
          FromPort: 3306
          ToPort: 3306
          SourceSecurityGroupId: !Ref ManagementSecurityGroup
          Description: MySQL access from management server
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Database-SG

Outputs:
  VPC:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub ${EnvironmentName}-VPC-ID

  PublicSubnets:
    Description: Public subnets
    Value: !Join [",", [!Ref PublicSubnet1, !Ref PublicSubnet2]]
    Export:
      Name: !Sub ${EnvironmentName}-Public-Subnets

  PrivateAppSubnets:
    Description: Private app subnets
    Value: !Join [",", [!Ref PrivateAppSubnet1, !Ref PrivateAppSubnet2]]
    Export:
      Name: !Sub ${EnvironmentName}-Private-App-Subnets

  PrivateDBSubnets:
    Description: Private DB subnets
    Value: !Join [",", [!Ref PrivateDBSubnet1, !Ref PrivateDBSubnet2]]
    Export:
      Name: !Sub ${EnvironmentName}-Private-DB-Subnets

  EKSClusterSecurityGroup:
    Description: EKS Cluster Security Group
    Value: !Ref EKSClusterSecurityGroup
    Export:
      Name: !Sub ${EnvironmentName}-EKS-Cluster-SG

  EKSNodeSecurityGroup:
    Description: EKS Node Security Group
    Value: !Ref EKSNodeSecurityGroup
    Export:
      Name: !Sub ${EnvironmentName}-EKS-Node-SG

  ManagementSecurityGroup:
    Description: Management Security Group
    Value: !Ref ManagementSecurityGroup
    Export:
      Name: !Sub ${EnvironmentName}-Management-SG

  DatabaseSecurityGroup:
    Description: Database Security Group
    Value: !Ref DatabaseSecurityGroup
    Export:
      Name: !Sub ${EnvironmentName}-Database-SG
```

## Stack 2: EC2 Management Server

### **02-ec2-stack.yaml**
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'EC2 Management Server for EKS Operations'

Parameters:
  EnvironmentName:
    Description: Environment name prefix
    Type: String
    Default: TaskAPI
    
  InstanceType:
    Description: EC2 instance type
    Type: String
    Default: t3a.medium
    AllowedValues:
      - t3a.small
      - t3a.medium
      - t3a.large
    
  KeyPairName:
    Description: EC2 Key Pair for SSH access
    Type: AWS::EC2::KeyPair::KeyName
    
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

Resources:
  # IAM Role for Management Server
  ManagementServerRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub ${EnvironmentName}-ManagementServer-Role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
      Policies:
        - PolicyName: EKSManagementPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - eks:*
                  - ec2:*
                  - iam:*
                  - cloudformation:*
                  - ecr:*
                  - logs:*
                  - ssm:*
                Resource: '*'

  ManagementServerInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Roles:
        - !Ref ManagementServerRole

  # Management Server Instance
  ManagementServer:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !Ref InstanceType
      KeyName: !Ref KeyPairName
      IamInstanceProfile: !Ref ManagementServerInstanceProfile
      SecurityGroupIds:
        - Fn::ImportValue: !Sub ${EnvironmentName}-Management-SG
      SubnetId:
        Fn::Select:
          - 0
          - Fn::Split:
            - ","
            - Fn::ImportValue: !Sub ${EnvironmentName}-Private-App-Subnets
      BlockDeviceMappings:
        - DeviceName: /dev/xvda
          Ebs:
            VolumeType: gp3
            VolumeSize: 30
            Encrypted: true
            DeleteOnTermination: true
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          
          # Install Docker
          yum install -y docker
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          
          # Install AWS CLI v2
          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          ./aws/install
          
          # Install kubectl
          curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
          chmod +x ./kubectl
          mv ./kubectl /usr/local/bin/kubectl
          
          # Install eksctl
          curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
          mv /tmp/eksctl /usr/local/bin
          
          # Install Helm
          curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
          
          # Install git
          yum install -y git
          
          # Install Java 17 for local development
          yum install -y java-17-amazon-corretto-devel
          
          # Install Maven
          cd /opt
          wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz
          tar xzf apache-maven-3.9.6-bin.tar.gz
          ln -s apache-maven-3.9.6 maven
          echo 'export PATH=/opt/maven/bin:$PATH' >> /etc/profile
          
          # Create working directory
          mkdir -p /home/ec2-user/workspace
          chown ec2-user:ec2-user /home/ec2-user/workspace
          
          # Install additional tools
          yum install -y htop tree jq
          
          # Signal completion
          /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource ManagementServer --region ${AWS::Region}
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Management-Server
        - Key: Environment
          Value: !Ref EnvironmentName
    CreationPolicy:
      ResourceSignal:
        Timeout: PT15M

  # Elastic IP for Management Server
  ManagementServerEIP:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      InstanceId: !Ref ManagementServer
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Management-EIP

Outputs:
  ManagementServerInstanceId:
    Description: Management Server Instance ID
    Value: !Ref ManagementServer
    Export:
      Name: !Sub ${EnvironmentName}-Management-Instance-ID

  ManagementServerPrivateIP:
    Description: Management Server Private IP
    Value: !GetAtt ManagementServer.PrivateIp
    Export:
      Name: !Sub ${EnvironmentName}-Management-Private-IP

  ManagementServerPublicIP:
    Description: Management Server Public IP
    Value: !Ref ManagementServerEIP
    Export:
      Name: !Sub ${EnvironmentName}-Management-Public-IP

  ManagementServerRole:
    Description: Management Server IAM Role
    Value: !Ref ManagementServerRole
    Export:
      Name: !Sub ${EnvironmentName}-Management-Role
```

## Stack 3: EKS Cluster

### **03-eks-stack.yaml**
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'EKS Cluster for Task Management API'

Parameters:
  EnvironmentName:
    Description: Environment name prefix
    Type: String
    Default: TaskAPI
    
  KubernetesVersion:
    Description: Kubernetes version
    Type: String
    Default: '1.28'
    
  NodeInstanceType:
    Description: EC2 instance type for worker nodes
    Type: String
    Default: t3.medium
    AllowedValues:
      - t3.small
      - t3.medium
      - t3.large
      - t3.xlarge
    
  NodeGroupDesiredSize:
    Description: Desired number of worker nodes
    Type: Number
    Default: 2
    MinValue: 1
    MaxValue: 10
    
  NodeGroupMinSize:
    Description: Minimum number of worker nodes
    Type: Number
    Default: 1
    MinValue: 1
    MaxValue: 10
    
  NodeGroupMaxSize:
    Description: Maximum number of worker nodes
    Type: Number
    Default: 5
    MinValue: 1
    MaxValue: 20

Resources:
  # EKS Cluster Service Role
  EKSClusterRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub ${EnvironmentName}-EKS-Cluster-Role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: eks.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

  # EKS Node Group Role
  EKSNodeRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub ${EnvironmentName}-EKS-Node-Role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

  # EKS Cluster
  EKSCluster:
    Type: AWS::EKS::Cluster
    Properties:
      Name: !Sub ${EnvironmentName}-EKS-Cluster
      Version: !Ref KubernetesVersion
      RoleArn: !GetAtt EKSClusterRole.Arn
      ResourcesVpcConfig:
        SecurityGroupIds:
          - Fn::ImportValue: !Sub ${EnvironmentName}-EKS-Cluster-SG
        SubnetIds:
          - Fn::Select:
            - 0
            - Fn::Split:
              - ","
              - Fn::ImportValue: !Sub ${EnvironmentName}-Private-App-Subnets
          - Fn::Select:
            - 1
            - Fn::Split:
              - ","
              - Fn::ImportValue: !Sub ${EnvironmentName}-Private-App-Subnets
          - Fn::Select:
            - 0
            - Fn::Split:
              - ","
              - Fn::ImportValue: !Sub ${EnvironmentName}-Public-Subnets
          - Fn::Select:
            - 1
            - Fn::Split:
              - ","
              - Fn::ImportValue: !Sub ${EnvironmentName}-Public-Subnets
        EndpointConfigPrivate: false
        EndpointConfigPublic: true
        PublicAccessCidrs:
          - 0.0.0.0/0
      Logging:
        ClusterLogging:
          EnabledTypes:
            - Type: api
            - Type: audit
            - Type: authenticator
            - Type: controllerManager
            - Type: scheduler
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-EKS-Cluster
        - Key: Environment
          Value: !Ref EnvironmentName

  # EKS Node Group
  EKSNodeGroup:
    Type: AWS::EKS::Nodegroup
    DependsOn: EKSCluster
    Properties:
      ClusterName: !Ref EKSCluster
      NodegroupName: !Sub ${EnvironmentName}-NodeGroup
      NodeRole: !GetAtt EKSNodeRole.Arn
      InstanceTypes:
        - !Ref NodeInstanceType
      AmiType: AL2_x86_64
      CapacityType: ON_DEMAND
      DiskSize: 30
      ScalingConfig:
        DesiredSize: !Ref NodeGroupDesiredSize
        MinSize: !Ref NodeGroupMinSize
        MaxSize: !Ref NodeGroupMaxSize
      UpdateConfig:
        MaxUnavailable: 1
      Subnets:
        - Fn::Select:
          - 0
          - Fn::Split:
            - ","
            - Fn::ImportValue: !Sub ${EnvironmentName}-Private-App-Subnets
        - Fn::Select:
          - 1
          - Fn::Split:
            - ","
            - Fn::ImportValue: !Sub ${EnvironmentName}-Private-App-Subnets
      RemoteAccess:
        Ec2SshKey: !Ref KeyPairName
        SourceSecurityGroups:
          - Fn::ImportValue: !Sub ${EnvironmentName}-Management-SG
      Tags:
        Environment: !Ref EnvironmentName
        NodeGroup: !Sub ${EnvironmentName}-NodeGroup

  # OIDC Identity Provider
  EKSClusterOIDCProvider:
    Type: AWS::IAM::OIDCIdentityProvider
    Properties:
      Url: !GetAtt EKSCluster.OpenIdConnectIssuerUrl
      ClientIdList:
        - sts.amazonaws.com
      ThumbprintList:
        - 9e99a48a9960b14926bb7f3b02e22da2b0ab7280

Outputs:
  EKSClusterName:
    Description: EKS Cluster Name
    Value: !Ref EKSCluster
    Export:
      Name: !Sub ${EnvironmentName}-EKS-Cluster-Name

  EKSClusterArn:
    Description: EKS Cluster ARN
    Value: !GetAtt EKSCluster.Arn
    Export:
      Name: !Sub ${EnvironmentName}-EKS-Cluster-ARN

  EKSClusterEndpoint:
    Description: EKS Cluster Endpoint
    Value: !GetAtt EKSCluster.Endpoint
    Export:
      Name: !Sub ${EnvironmentName}-EKS-Cluster-Endpoint

  EKSNodeGroupName:
    Description: EKS Node Group Name
    Value: !Ref EKSNodeGroup
    Export:
      Name: !Sub ${EnvironmentName}-EKS-NodeGroup-Name

  EKSClusterOIDCIssuerURL:
    Description: EKS Cluster OIDC Issuer URL
    Value: !GetAtt EKSCluster.OpenIdConnectIssuerUrl
    Export:
      Name: !Sub ${EnvironmentName}-EKS-OIDC-Issuer-URL
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
