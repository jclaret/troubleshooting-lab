#!/bin/bash

# Fix script for file upload PVC expansion
# This script expands the PVC to resolve storage space issues

echo "Fixing file upload storage issue..."

# Check if PVC exists
if ! oc get pvc upload-data -n odf-file >/dev/null 2>&1; then
    echo "ERROR: PVC upload-data not found in namespace odf-file"
    echo "Please deploy the application first with: oc apply -k ."
    exit 1
fi

echo "Current PVC size:"
oc get pvc upload-data -n odf-file -o jsonpath='{.spec.resources.requests.storage}'
echo ""

echo "Expanding PVC to 1Gi..."
oc patch pvc upload-data -n odf-file --type=merge -p '{
  "spec": { "resources": { "requests": { "storage": "1Gi" } } }
}'

echo ""
echo "Monitoring PVC expansion..."
oc describe pvc upload-data -n odf-file | grep -i resize

echo ""
echo "Waiting for expansion to complete..."
sleep 10

echo "Checking new PVC size:"
oc get pvc upload-data -n odf-file -o jsonpath='{.spec.resources.requests.storage}'
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
echo "✅ PVC expansion complete!"
echo "The PVC is now 1Gi and file uploads should work properly."
echo "Test by uploading files at: http://$(oc get route image-uploader -n odf-file -o jsonpath='{.spec.host}')"
