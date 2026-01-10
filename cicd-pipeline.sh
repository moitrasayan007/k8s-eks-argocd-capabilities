#!/bin/bash

# CI/CD Pipeline Script
set -e

# Variables
NEW_VERSION=${1:-"1.0.0"}
CHART_NAME="nodejs-app"
IMAGE_TAG=${2:-"latest"}
AWS_REGION="us-west-1"
AWS_ACCOUNT_ID="501294308535"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "🚀 Starting CI/CD Pipeline for version: ${NEW_VERSION}"

# Step 1: Update Helm Chart version
echo "📦 Updating Helm Chart version to ${NEW_VERSION}"
sed -i '' "s/version: .*/version: ${NEW_VERSION}/" helm/${CHART_NAME}/Chart.yaml
sed -i '' "s/appVersion: .*/appVersion: \"${NEW_VERSION}\"/" helm/${CHART_NAME}/Chart.yaml

# Step 2: Push Helm Chart to ECR
echo "🏗️ Building and pushing Helm chart to ECR"
aws ecr get-login-password --region ${AWS_REGION} | helm registry login --username AWS --password-stdin ${ECR_REGISTRY}
helm package helm/${CHART_NAME}
helm push ${CHART_NAME}-${NEW_VERSION}.tgz oci://${ECR_REGISTRY}/helm

# Step 3: Update Kustomize image tags
echo "🔄 Updating Kustomize image tags"
cd kustomize/base
kustomize edit set image nginx=${IMAGE_TAG}
cd ../overlays/prod
kustomize edit set image nginx=${IMAGE_TAG}
cd ../../..

# Step 4: Update ArgoCD Application targetRevision
echo "🎯 Updating ArgoCD Application targetRevision"
sed -i '' "s/targetRevision: .*/targetRevision: ${NEW_VERSION}/" argocd/nodejs-app-ecr.yaml

# Step 5: Commit and push changes
echo "📝 Committing changes to Git"
git add .
git commit -m "CI/CD: Update to version ${NEW_VERSION} with image ${IMAGE_TAG}"
git push origin master

echo "✅ CI/CD Pipeline completed successfully!"
echo "🔍 ArgoCD will automatically sync the new version: ${NEW_VERSION}"