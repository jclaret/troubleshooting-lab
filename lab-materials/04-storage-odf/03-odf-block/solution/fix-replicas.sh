#!/bin/bash

# Fix script for block storage replica issue
# This script scales the deployment to 1 replica to resolve the multi-attach problem

echo "Fixing block storage replica issue..."

# Check if deployment exists
if ! oc get deployment rbd-hello -n odf-block >/dev/null 2>&1; then
    echo "ERROR: Deployment rbd-hello not found in namespace odf-block"
    echo "Please deploy the application first with: oc apply -k ."
    exit 1
fi

echo "Current deployment replicas:"
oc get deployment rbd-hello -n odf-block -o jsonpath='{.spec.replicas}'
echo ""

echo "Scaling deployment to 1 replica..."
oc scale deployment rbd-hello --replicas=1 -n odf-block

echo ""
echo "Waiting for scaling to complete..."
oc rollout status deployment/rbd-hello -n odf-block

echo ""
echo "Checking pod status after scaling..."
oc get pods -l app=rbd-hello -n odf-block -o wide

echo ""
echo "Testing application functionality..."
ROUTE=$(oc get route rbd-hello -n odf-block -o jsonpath='{.spec.host}')
if [ ! -z "$ROUTE" ]; then
    echo "Application URL: http://$ROUTE"
    curl -s http://$ROUTE/ | head -3
else
    echo "Route not found"
fi

echo ""
echo "✅ Replica scaling complete!"
echo "The deployment is now running with 1 replica, resolving the multi-attach issue."
echo "Test the application at: http://$ROUTE"
