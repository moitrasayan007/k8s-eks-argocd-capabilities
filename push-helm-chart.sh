#!/bin/bash

# Variables
AWS_REGION="us-west-1"
AWS_ACCOUNT_ID="501294308535"
CHART_NAME="nodejs-app"
CHART_VERSION="0.1.0"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Create ECR repository for Helm charts
aws ecr create-repository --repository-name ${CHART_NAME} --region ${AWS_REGION} || true

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | helm registry login --username AWS --password-stdin ${ECR_REGISTRY}

# Copy values file to chart directory
cp values-ecr.yaml helm/${CHART_NAME}/

# Package the chart
helm package helm/${CHART_NAME}

# Push to ECR root
helm push ${CHART_NAME}-${CHART_VERSION}.tgz oci://${ECR_REGISTRY}

echo "Chart pushed to: oci://${ECR_REGISTRY}/${CHART_NAME}:${CHART_VERSION}"
echo "Deploy with: kubectl apply -f argocd/nodejs-app-ecr.yaml"