#!/bin/bash

# Canary Promotion Script
set -e

STAGE=${1:-"deploy"}
CHART_NAME="nodejs-app"
NEW_VERSION=${2:-"1.4.0"}

case $STAGE in
  "deploy")
    echo "🚀 Step 1: Deploy with setProductionState=true (PRODUCTION_STATE=test)"
    sed -i '' "s/setProductionState: .*/setProductionState: true/" helm/${CHART_NAME}/values.yaml
    
    # Update chart version and push
    sed -i '' "s/version: .*/version: ${NEW_VERSION}/" helm/${CHART_NAME}/Chart.yaml
    aws ecr get-login-password --region us-west-1 | helm registry login --username AWS --password-stdin 501294308535.dkr.ecr.us-west-1.amazonaws.com
    helm package helm/${CHART_NAME}
    helm push ${CHART_NAME}-${NEW_VERSION}.tgz oci://501294308535.dkr.ecr.us-west-1.amazonaws.com/helm
    
    # Update ArgoCD app
    sed -i '' "s/targetRevision: .*/targetRevision: ${NEW_VERSION}/" argocd/nodejs-app-ecr.yaml
    
    git add . && git commit -m "Deploy: setProductionState=true, version=${NEW_VERSION}" && git push
    echo "✅ Deployed with test environment"
    echo "Next: ./canary-promote.sh promote-canary ${NEW_VERSION}"
    ;;
    
  "promote-canary")
    echo "🔄 Step 2: Promote Canary (PRODUCTION_STATE=live, delete deploy)"
    # Update to next stage in values
    sed -i '' "s/canaryStage: .*/canaryStage: \"promote-canary\"/" helm/${CHART_NAME}/values.yaml
    
    # Update and push chart
    helm package helm/${CHART_NAME}
    helm push ${CHART_NAME}-${NEW_VERSION}.tgz oci://501294308535.dkr.ecr.us-west-1.amazonaws.com/helm
    
    git add . && git commit -m "Promote Canary: stage=promote-canary" && git push
    echo "✅ Canary promoted to live environment"
    echo "Next: ./canary-promote.sh promote-live ${NEW_VERSION}"
    ;;
    
  "promote-live")
    echo "🎯 Step 3: Promote to Live (canary becomes production)"
    sed -i '' "s/setProductionState: .*/setProductionState: false/" helm/${CHART_NAME}/values.yaml
    
    # Update chart version
    NEW_LIVE_VERSION="${NEW_VERSION%.*}.$((${NEW_VERSION##*.}+1))"
    sed -i '' "s/version: .*/version: ${NEW_LIVE_VERSION}/" helm/${CHART_NAME}/Chart.yaml
    
    # Push updated chart
    helm package helm/${CHART_NAME}
    helm push ${CHART_NAME}-${NEW_LIVE_VERSION}.tgz oci://501294308535.dkr.ecr.us-west-1.amazonaws.com/helm
    
    # Update ArgoCD app
    sed -i '' "s/targetRevision: .*/targetRevision: ${NEW_LIVE_VERSION}/" argocd/nodejs-app-ecr.yaml
    
    git add . && git commit -m "Promote Live: setProductionState=false, version=${NEW_LIVE_VERSION}" && git push
    echo "✅ Canary promoted to full production"
    echo "🎉 Canary deployment completed!"
    ;;
    
  *)
    echo "Usage: $0 {deploy|promote-canary|promote-live} [version]"
    exit 1
    ;;
esac