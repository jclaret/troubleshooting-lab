#!/bin/bash

# Test script for file upload functionality
# This script helps test the file upload application

echo "Testing file upload functionality..."

# Get the route
ROUTE=$(oc get route image-uploader -n odf-file -o jsonpath='{.spec.host}')
if [ -z "$ROUTE" ]; then
    echo "ERROR: Route not found. Make sure the application is deployed."
    exit 1
fi

echo "Application URL: http://$ROUTE"
echo ""
echo "Testing basic connectivity..."
curl -s http://$ROUTE/ | head -10

echo ""
echo "Checking PVC size..."
oc get pvc upload-data -n odf-file -o jsonpath='{.spec.resources.requests.storage}'
echo ""

echo "Checking storage class..."
oc get pvc upload-data -n odf-file -o jsonpath='{.spec.storageClassName}'
echo "Note: Investigate what type of storage this is and if it supports expansion"
echo ""

echo "Checking available space in pod..."
POD=$(oc get pods -n odf-file -l app=image-uploader -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$POD" ]; then
    echo "Available space in pod:"
    oc rsh -n odf-file $POD df -h /data
else
    echo "No pods found"
fi

echo ""
echo "To test file upload:"
echo "1. Open http://$ROUTE in your browser"
echo "2. Try to upload a file (you should get a storage space error)"
echo "3. Check the application logs: oc logs -n odf-file -l app=image-uploader"
