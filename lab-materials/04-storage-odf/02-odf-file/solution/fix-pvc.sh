#!/bin/bash

# Fix script for file upload PVC recreation
# This script recreates the PVC with correct size and access mode

echo "Fixing file upload storage issue..."

# Check if PVC exists
if ! oc get pvc upload-data -n odf-file >/dev/null 2>&1; then
    echo "ERROR: PVC upload-data not found in namespace odf-file"
    echo "Please deploy the application first with: oc apply -k ."
    exit 1
fi

echo "Current PVC configuration:"
echo "Size: $(oc get pvc upload-data -n odf-file -o jsonpath='{.spec.resources.requests.storage}')"
echo "AccessMode: $(oc get pvc upload-data -n odf-file -o jsonpath='{.spec.accessModes[0]}')"
echo ""

echo "Scaling down deployment to avoid PVC conflicts..."
oc scale deployment image-uploader -n odf-file --replicas=0

echo ""
echo "Waiting for pods to terminate..."
sleep 10

echo "Deleting existing PVC..."
oc delete pvc upload-data -n odf-file

echo ""
echo "Creating new PVC with ReadWriteMany and 1Gi..."
oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: upload-data
  namespace: odf-file
spec:
  storageClassName: ocs-storagecluster-cephfs
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 1Gi
EOF

echo ""
echo "Scaling deployment back to 3 replicas..."
oc scale deployment image-uploader -n odf-file --replicas=3

echo ""
echo "Waiting for pods to start with new PVC..."
sleep 15

echo "Checking pod status..."
oc get pods -n odf-file

echo ""
echo "Checking new PVC configuration:"
echo "Size: $(oc get pvc upload-data -n odf-file -o jsonpath='{.spec.resources.requests.storage}')"
echo "AccessMode: $(oc get pvc upload-data -n odf-file -o jsonpath='{.spec.accessModes[0]}')"
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
echo "✅ PVC recreation complete!"
echo "The PVC is now 1Gi with ReadWriteMany access mode."
echo "All 3 replicas should be running and file uploads should work properly."
echo "Test by uploading files at: http://$(oc get route image-uploader -n odf-file -o jsonpath='{.spec.host}')"
