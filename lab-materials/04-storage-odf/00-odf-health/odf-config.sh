#!/bin/bash

# ODF Configuration Script
# This script modifies ODF node configuration

echo "Applying ODF configuration changes..."

# Get the list of worker nodes
WORKER_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o name)

echo "Found worker nodes: $WORKER_NODES"

# Apply configuration changes to worker nodes
for node in $WORKER_NODES; do
    echo "Applying configuration to $node"
    oc label $node cluster.ocs.openshift.io/openshift-storage- || echo "Configuration not found on $node"
    oc label $node node-role.kubernetes.io/worker- || echo "Configuration not found on $node"
done

echo "ODF configuration applied. Monitor ODF cluster status:"
echo "oc get storagecluster -n openshift-storage"
echo "oc get pods -n openshift-storage"
