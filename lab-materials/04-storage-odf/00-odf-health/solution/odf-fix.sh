#!/bin/bash

# ODF Fix Script
# This script restores ODF cluster configuration

echo "Applying ODF fix configuration..."

# Read the saved list of storage nodes
if [ -f /tmp/odf-storage-nodes.txt ]; then
    STORAGE_NODES=$(cat /tmp/odf-storage-nodes.txt)
    echo "Restoring configuration to: $STORAGE_NODES"
    
    for node in $STORAGE_NODES; do
        echo "Applying fix to $node"
        oc label $node cluster.ocs.openshift.io/openshift-storage=""
    done
else
    echo "No storage nodes list found. Using fallback method..."
    # Fallback: find nodes that have OSD pods
    STORAGE_NODES=$(oc get pods -n openshift-storage -l app=rook-ceph-osd -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u)
    for node in $STORAGE_NODES; do
        echo "Applying fix to node/$node"
        oc label node/$node cluster.ocs.openshift.io/openshift-storage=""
    done
fi

echo "ODF fix configuration applied. Monitor ODF cluster recovery:"
echo "oc get storagecluster -n openshift-storage -w"
echo "oc get pods -n openshift-storage -w"
