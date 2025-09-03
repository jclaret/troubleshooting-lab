#!/bin/bash

# ODF Configuration Script
# This script removes ODF storage label from a worker node and deletes ODF pods

echo "Applying ODF configuration changes..."

# Get worker nodes from the worker MCP
WORKER_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o name)

if [ -z "$WORKER_NODES" ]; then
    echo "No worker nodes found."
    exit 1
fi

# Select the first worker node
TARGET_NODE=$(echo "$WORKER_NODES" | head -1 | sed 's/node\///')
echo "Selected target node: $TARGET_NODE"

# Save the target node name for the fix script
echo "$TARGET_NODE" > /tmp/odf-target-node.txt

# Remove ODF storage label from the target node
echo "Removing ODF storage label from node: $TARGET_NODE"
oc label node/$TARGET_NODE cluster.ocs.openshift.io/openshift-storage- || echo "Label not found on $TARGET_NODE"

# Delete ODF pods running on the target node
echo "Deleting ODF pods running on node: $TARGET_NODE"
oc get pods -n openshift-storage -o wide | grep "$TARGET_NODE" | awk '{print $1}' | while read pod; do
    if [ ! -z "$pod" ]; then
        echo "Deleting pod: $pod"
        oc delete pod $pod -n openshift-storage --force --grace-period=0
    fi
done

echo "ODF configuration applied. Monitor ODF cluster status:"
echo "oc get storagecluster -n openshift-storage"
echo "oc get pods -n openshift-storage"
