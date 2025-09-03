#!/bin/bash

# Script to restore ODF storage labels to nodes
# This fixes the node labeling issue and restores ODF cluster health

echo "Restoring ODF storage labels to nodes..."

# Get the list of worker nodes (first 3 for ODF storage)
WORKER_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o name | head -3)

echo "Found worker nodes: $WORKER_NODES"

# Restore ODF storage labels to worker nodes
for node in $WORKER_NODES; do
    echo "Restoring labels to $node"
    oc label $node cluster.ocs.openshift.io/openshift-storage=""
    oc label $node node-role.kubernetes.io/worker=""
done

echo "ODF storage labels restored. Monitor ODF cluster recovery:"
echo "oc get storagecluster -n openshift-storage -w"
echo "oc get pods -n openshift-storage -w"
