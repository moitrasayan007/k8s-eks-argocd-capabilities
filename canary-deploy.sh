#!/bin/bash

# Canary Deployment Script
set -e

STAGE=${1:-"deploy"}

case $STAGE in
  "deploy")
    echo "🚀 Step 1: Deploy Canary (PRODUCTION_STATE=test, 1 replica)"
    kubectl apply -f argocd/nodejs-canary-apps.yaml
    kubectl patch app nodejs-canary-deploy -n argocd --type merge -p '{"operation":{"sync":{}}}'
    echo "✅ Canary deployed with test environment"
    echo "Next: ./canary-deploy.sh promote-canary"
    ;;
    
  "promote-canary")
    echo "🔄 Step 2: Promote Canary (PRODUCTION_STATE=live, 1 replica)"
    kubectl patch app nodejs-canary-promote-canary -n argocd --type merge -p '{"operation":{"sync":{}}}'
    echo "✅ Canary promoted to live environment"
    echo "Next: ./canary-deploy.sh shift-canary"
    ;;
    
  "shift-canary")
    echo "📈 Step 3: Shift Traffic (PRODUCTION_STATE=live, 2 replicas)"
    kubectl patch app nodejs-canary-shift-canary -n argocd --type merge -p '{"operation":{"sync":{}}}'
    echo "✅ Traffic shifted to canary"
    echo "Next: ./canary-deploy.sh promote-live"
    ;;
    
  "promote-live")
    echo "🎯 Step 4: Promote to Live (PRODUCTION_STATE=live, 3 replicas)"
    kubectl patch app nodejs-canary-promote-live -n argocd --type merge -p '{"operation":{"sync":{}}}'
    echo "✅ Canary promoted to full production"
    echo "🎉 Canary deployment completed!"
    ;;
    
  *)
    echo "Usage: $0 {deploy|promote-canary|shift-canary|promote-live}"
    exit 1
    ;;
esac