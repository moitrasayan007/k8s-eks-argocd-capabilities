#!/bin/bash

# Git-based Canary Promotion Script
set -e

STAGE=${1:-"deploy"}

case $STAGE in
  "deploy")
    echo "🚀 Step 1: Deploy Canary (PRODUCTION_STATE=test)"
    cp canary/deploy.yaml canary-active.yaml
    
    git add canary-active.yaml
    git commit -m "Deploy: Start canary with PRODUCTION_STATE=test"
    git push origin master
    
    echo "✅ Canary deployed with test environment"
    echo "Next: ./git-canary-promote.sh promote-canary"
    ;;
    
  "promote-canary")
    echo "🔄 Step 2: Promote Canary (PRODUCTION_STATE=live, delete deploy)"
    cp canary/promote-canary.yaml canary-active.yaml
    
    git add canary-active.yaml
    git commit -m "Promote Canary: PRODUCTION_STATE=live, delete deploy pods"
    git push origin master
    
    echo "✅ Deploy pods terminated, canary promoted to live"
    echo "Next: ./git-canary-promote.sh promote-live"
    ;;
    
  "promote-live")
    echo "🎯 Step 3: Promote to Live (canary becomes production)"
    cp canary/promote-live.yaml canary-active.yaml
    
    git add canary-active.yaml
    git commit -m "Promote Live: Canary promoted to full production"
    git push origin master
    
    echo "✅ Canary promoted to full production"
    echo "🎉 Canary deployment completed!"
    ;;
    
  *)
    echo "Usage: $0 {deploy|promote-canary|promote-live}"
    exit 1
    ;;
esac