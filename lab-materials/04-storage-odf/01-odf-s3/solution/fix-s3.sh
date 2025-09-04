#!/bin/bash

# Fix script for S3 authentication issue
# This script fixes the bucket and credential configuration mismatch

echo "Fixing object storage authentication issue..."

# Check if deployment exists
if ! oc get deployment s3-uploader -n odf-s3 >/dev/null 2>&1; then
    echo "ERROR: Deployment s3-uploader not found in namespace odf-s3"
    echo "Please deploy the application first with: oc apply -k ."
    exit 1
fi

echo "Current configuration issue:"
echo "The application is using credentials from 'img-bucket-a' but trying to access 'img-bucket-b'"
echo ""

echo "Fixing the ConfigMap reference in deployment..."
oc patch deployment s3-uploader -n odf-s3 --type=json -p='[
  {"op":"replace","path":"/spec/template/spec/containers/0/env/2/valueFrom/configMapKeyRef/name","value":"img-bucket-a"}
]'

echo ""
echo "Restarting deployment to apply changes..."
oc rollout restart deployment/s3-uploader -n odf-s3

echo ""
echo "Waiting for deployment to be ready..."
oc rollout status deployment/s3-uploader -n odf-s3

echo ""
echo "Checking pod status after fix..."
oc get pods -l app=s3-uploader -n odf-s3

echo ""
echo "Testing application functionality..."
ROUTE=$(oc get route s3-uploader -n odf-s3 -o jsonpath='{.spec.host}')
if [ ! -z "$ROUTE" ]; then
    echo "Application URL: http://$ROUTE"
    curl -s http://$ROUTE/ | head -5
else
    echo "Route not found"
fi

echo ""
echo "Checking application logs for success..."
oc logs -l app=s3-uploader -n odf-s3 --tail=5

echo ""
echo "✅ S3 authentication fix complete!"
echo "The application should now be able to access the object storage bucket."
echo "Test by uploading files at: http://$ROUTE"
