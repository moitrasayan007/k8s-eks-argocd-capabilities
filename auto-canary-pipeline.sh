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
            python3 -c "import re; content=open('values.yaml').read(); open('values.yaml','w').write(re.sub(r'canaryStage: \"deploy\"', 'canaryStage: \"promote-canary\"', content))"
            
            git add canary-active.yaml values.yaml
            git commit -m "Auto-Deploy: PRODUCTION_STATE=test, next: promote-canary"
            git push origin master
            
            echo "✅ Deploy completed, auto-progressing to promote-canary"
            ;;
            
        "promote-canary")
            echo "🔄 Stage 2: Promote Canary (PRODUCTION_STATE=live, delete deploy)"
            cp canary/promote-canary.yaml canary-active.yaml
            
            # Auto-progress to next stage
            python3 -c "import re; content=open('values.yaml').read(); open('values.yaml','w').write(re.sub(r'canaryStage: \"promote-canary\"', 'canaryStage: \"promote-live\"', content))"
            
            git add canary-active.yaml values.yaml
            git commit -m "Auto-Promote Canary: PRODUCTION_STATE=live, next: promote-live"
            git push origin master
            
            echo "✅ Canary promoted, auto-progressing to promote-live"
            ;;
            
        "promote-live")
            echo "🎯 Stage 3: Promote to Live (canary becomes production)"
            cp canary/promote-live.yaml canary-active.yaml
            
            # Reset to normal state
            python3 -c "import re; content=open('values.yaml').read(); content=re.sub(r'setProductionState: true', 'setProductionState: false', content); content=re.sub(r'canaryStage: \"promote-live\"', 'canaryStage: \"deploy\"', content); open('values.yaml','w').write(content)"
            
            git add canary-active.yaml values.yaml
            git commit -m "Auto-Promote Live: Canary completed, reset to normal"
            git push origin master
            
            echo "✅ Canary promoted to production, pipeline completed!"
            ;;
    esac
else
    echo "ℹ️  setProductionState is false, no canary deployment needed"
fi