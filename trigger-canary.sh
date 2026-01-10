#!/bin/bash

# Trigger Automated Canary Pipeline
set -e

echo "🚀 Starting Automated Canary Pipeline"

# Set values.yaml to trigger canary
sed -i '' 's/setProductionState: false/setProductionState: true/' values.yaml
sed -i '' 's/canaryStage: .*/canaryStage: "deploy"/' values.yaml

git add values.yaml
git commit -m "Trigger: Start automated canary pipeline"
git push origin master

echo "✅ Pipeline triggered! GitHub Actions will handle the automation."
echo "📊 Monitor progress at: https://github.com/moitrasayan007/k8s-eks-argocd-capabilities/actions"