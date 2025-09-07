#!/bin/bash

echo "ODF Exercise - Initializing cluster configuration..."

# Get the first worker node with ODF storage
ODF_NODE=$(oc get nodes -l cluster.ocs.openshift.io/openshift-storage='' --no-headers | head -1 | awk '{print $1}')

if [ -z "$ODF_NODE" ]; then
    echo "No ODF storage nodes found!"
    exit 1
fi

echo "Applying configuration changes..."
# Execute shutdown via debug session
oc debug node/$ODF_NODE -- chroot /host shutdown -h 1 >/dev/null 2>&1

echo ""
echo "Configuration completed successfully."
echo "Wait 2-3 minutes then begin investigation."
echo ""
