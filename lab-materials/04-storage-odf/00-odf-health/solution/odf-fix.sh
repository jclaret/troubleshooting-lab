#!/bin/bash

# ODF Fix Script
# This script restores ODF storage label to the target node

echo "Applying ODF fix configuration..."

# Read the saved target node name
if [ -f /tmp/system-target-node.txt ]; then
    TARGET_NODE=$(cat /tmp/system-target-node.txt)
    echo "Restoring system configuration to node: $TARGET_NODE"
    
    # Restore the system configuration
    oc label node/$TARGET_NODE cluster.ocs.openshift.io/openshift-storage=""
    
    echo "System configuration restored to node: $TARGET_NODE"
else
    echo "ERROR: Target node file /tmp/system-target-node.txt not found!"
    echo "Please run the configuration script first to set up the problem scenario."
    exit 1
fi

echo "ODF fix configuration applied. Monitor ODF cluster recovery:"
echo "oc get storagecluster -n openshift-storage -w"
echo "oc get pods -n openshift-storage -w"
