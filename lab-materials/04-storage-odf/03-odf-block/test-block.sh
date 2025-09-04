#!/bin/bash

# Test script for block storage functionality
# This script helps test the block storage application

echo "Testing block storage application..."

# Get the route
ROUTE=$(oc get route rbd-hello -n odf-block -o jsonpath='{.spec.host}')
if [ -z "$ROUTE" ]; then
    echo "ERROR: Route not found. Make sure the application is deployed."
    exit 1
fi

echo "Application URL: http://$ROUTE"
echo ""

echo "Checking deployment status..."
oc get deployment rbd-hello -n odf-block

echo ""
echo "Checking pod status..."
oc get pods -l app=rbd-hello -n odf-block -o wide

echo ""
echo "Checking PVC configuration..."
oc get pvc rbd-hello-pvc -n odf-block
echo "PVC Access Mode:"
oc get pvc rbd-hello-pvc -n odf-block -o jsonpath='{.spec.accessModes[0]}'
echo ""

echo "Checking storage class..."
oc get pvc rbd-hello-pvc -n odf-block -o jsonpath='{.spec.storageClassName}'
echo "Note: Investigate what type of storage this is and what access modes it supports"
echo ""

echo "Checking pod events for scheduling issues..."
oc get events -n odf-block --sort-by='.lastTimestamp' | grep -i "rbd-hello" | tail -5

echo ""
echo "Testing basic connectivity..."
curl -s http://$ROUTE/ | head -5

echo ""
echo "To investigate the problem:"
echo "1. Check why some pods are not running: oc describe pod -l app=rbd-hello -n odf-block"
echo "2. Investigate the PVC access mode and storage type"
echo "3. Consider if multiple pods can access the same volume simultaneously"
