#!/bin/bash

# ODF Fix Script
# This script restores ODF storage label to the target node

echo "Applying ODF fix configuration..."

# Read the saved target node name
if [ -f /tmp/odf-target-node.txt ]; then
    TARGET_NODE=$(cat /tmp/odf-target-node.txt)
    echo "Restoring ODF storage label to node: $TARGET_NODE"
    
    # Restore the ODF storage label
    oc label node/$TARGET_NODE cluster.ocs.openshift.io/openshift-storage=""
    
    echo "ODF storage label restored to node: $TARGET_NODE"
else
    echo "ERROR: Target node file /tmp/odf-target-node.txt not found!"
    echo "Please run the odf-config.sh script first to set up the problem scenario."
    exit 1
fi

echo "ODF fix configuration applied. Monitor ODF cluster recovery:"
echo "oc get storagecluster -n openshift-storage -w"
echo "oc get pods -n openshift-storage -w"
