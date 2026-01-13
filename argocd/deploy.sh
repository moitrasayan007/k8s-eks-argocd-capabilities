#!/bin/bash

# Blue-Green Deployment Script
# Usage: ./deploy.sh [deploy|promote]

PHASE=${1:-deploy}
VALUES_FILE="values.yaml"

case $PHASE in
  "deploy")
    echo "Phase 1: Deploy to test environment"
    # Update values for test deployment
    yq e '.deployment.setProductionState = true' -i $VALUES_FILE
    yq e '.deployment.productionState = "test"' -i $VALUES_FILE
    
    git add $VALUES_FILE
    git commit -m "Deploy phase: PRODUCTION_STATE=test"
    git push
    
    echo "Waiting for ArgoCD sync..."
    sleep 30
    
    echo "Check rollout status: kubectl argo rollouts get rollout blue-green-app -n default"
    ;;
    
  "promote")
    echo "Phase 2: Promote canary to live"
    # Update values for live promotion
    yq e '.deployment.productionState = "live"' -i $VALUES_FILE
    
    git add $VALUES_FILE
    git commit -m "Promote phase: PRODUCTION_STATE=live"
    git push
    
    echo "Waiting for ArgoCD sync..."
    sleep 30
    
    echo "Promoting rollout..."
    kubectl argo rollouts promote blue-green-app -n default
    
    echo "Rollout promoted to live!"
    ;;
    
  *)
    echo "Usage: $0 [deploy|promote]"
    echo "  deploy  - Deploy new version to test (PRODUCTION_STATE=test)"
    echo "  promote - Promote to live (PRODUCTION_STATE=live)"
    exit 1
    ;;
esac