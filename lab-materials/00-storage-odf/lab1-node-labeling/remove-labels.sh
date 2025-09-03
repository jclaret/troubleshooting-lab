#!/bin/bash

# Script to remove ODF storage labels from nodes
# This simulates a node labeling issue that causes ODF cluster degradation

echo "Removing ODF storage labels from nodes..."

# Get the list of worker nodes
WORKER_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o name)

echo "Found worker nodes: $WORKER_NODES"

# Remove ODF storage labels from all worker nodes
for node in $WORKER_NODES; do
    echo "Removing labels from $node"
    oc label $node cluster.ocs.openshift.io/openshift-storage- || echo "Label not found on $node"
    oc label $node node-role.kubernetes.io/worker- || echo "Label not found on $node"
done

echo "ODF storage labels removed. Monitor ODF cluster status:"
echo "oc get storagecluster -n openshift-storage"
echo "oc get pods -n openshift-storage"
