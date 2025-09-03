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
    echo "No target node found. Using fallback method..."
    # Fallback: find worker nodes and add label to first one
    WORKER_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o name | head -1 | sed 's/node\///')
    if [ ! -z "$WORKER_NODES" ]; then
        echo "Applying fix to worker node: $WORKER_NODES"
        oc label node/$WORKER_NODES cluster.ocs.openshift.io/openshift-storage=""
    fi
fi

echo "ODF fix configuration applied. Monitor ODF cluster recovery:"
echo "oc get storagecluster -n openshift-storage -w"
echo "oc get pods -n openshift-storage -w"
