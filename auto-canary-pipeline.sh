#!/bin/bash

# Automated Canary Pipeline
set -e

# Read values from values.yaml
PRODUCTION_STATE=$(grep "setProductionState:" values.yaml | awk '{print $2}')
CANARY_STAGE=$(grep "canaryStage:" values.yaml | awk '{print $2}' | tr -d '"')

echo "🔍 Current state: setProductionState=$PRODUCTION_STATE, canaryStage=$CANARY_STAGE"

if [ "$PRODUCTION_STATE" = "true" ]; then
    case $CANARY_STAGE in
        "deploy")
            echo "🚀 Stage 1: Deploy Canary (PRODUCTION_STATE=test)"
            cp canary/deploy.yaml canary-active.yaml
            
            # Auto-progress to next stage
            sed -i '' 's/canaryStage: "deploy"/canaryStage: "promote-canary"/' values.yaml
            
            git add canary-active.yaml values.yaml
            git commit -m "Auto-Deploy: PRODUCTION_STATE=test, next: promote-canary"
            git push origin master
            
            echo "✅ Deploy completed, auto-progressing to promote-canary"
            ;;
            
        "promote-canary")
            echo "🔄 Stage 2: Promote Canary (PRODUCTION_STATE=live, delete deploy)"
            cp canary/promote-canary.yaml canary-active.yaml
            
            # Auto-progress to next stage
            sed -i '' 's/canaryStage: "promote-canary"/canaryStage: "promote-live"/' values.yaml
            
            git add canary-active.yaml values.yaml
            git commit -m "Auto-Promote Canary: PRODUCTION_STATE=live, next: promote-live"
            git push origin master
            
            echo "✅ Canary promoted, auto-progressing to promote-live"
            ;;
            
        "promote-live")
            echo "🎯 Stage 3: Promote to Live (canary becomes production)"
            cp canary/promote-live.yaml canary-active.yaml
            
            # Reset to normal state
            sed -i '' 's/setProductionState: true/setProductionState: false/' values.yaml
            sed -i '' 's/canaryStage: "promote-live"/canaryStage: "deploy"/' values.yaml
            
            git add canary-active.yaml values.yaml
            git commit -m "Auto-Promote Live: Canary completed, reset to normal"
            git push origin master
            
            echo "✅ Canary promoted to production, pipeline completed!"
            ;;
    esac
else
    echo "ℹ️  setProductionState is false, no canary deployment needed"
fi