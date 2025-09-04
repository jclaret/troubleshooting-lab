#!/bin/bash

# Test script for object storage functionality
# This script helps test the object storage application

echo "Testing object storage application..."

# Get the route
ROUTE=$(oc get route s3-uploader -n odf-s3 -o jsonpath='{.spec.host}')
if [ -z "$ROUTE" ]; then
    echo "ERROR: Route not found. Make sure the application is deployed."
    exit 1
fi

echo "Application URL: http://$ROUTE"
echo ""

echo "Checking deployment status..."
oc get deployment s3-uploader -n odf-s3

echo ""
echo "Checking pod status..."
oc get pods -l app=s3-uploader -n odf-s3 -o wide

echo ""
echo "Checking ObjectBucketClaim status..."
oc get obc -n odf-s3

echo ""
echo "Checking generated ConfigMaps and Secrets..."
oc get cm -n odf-s3 | grep img-bucket
oc get secret -n odf-s3 | grep img-bucket

echo ""
echo "Checking application logs for errors..."
oc logs -l app=s3-uploader -n odf-s3 --tail=10

echo ""
echo "Checking environment configuration..."
oc describe deployment s3-uploader -n odf-s3 | grep -A 20 Environment

echo ""
echo "Testing basic connectivity..."
curl -s http://$ROUTE/ | head -5

echo ""
echo "To investigate the problem:"
echo "1. Check application logs: oc logs -l app=s3-uploader -n odf-s3"
echo "2. Investigate the bucket and credential configuration mismatch"
echo "3. Look for 'Access Denied' or authentication errors"
echo "4. Check if the bucket name matches the credentials being used"
