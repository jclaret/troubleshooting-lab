#!/bin/bash

# System Configuration Script
# This script applies system configuration changes

# Find nodes with active rook-ceph-mon pods
MON_NODES=$(oc get pods -n openshift-storage -l app=rook-ceph-mon -o wide --no-headers | grep Running | awk '{print $7}' | sort -u)

if [ -z "$MON_NODES" ]; then
    exit 1
fi

# Select the first node with an active mon pod
TARGET_NODE=$(echo "$MON_NODES" | head -1)

# Save target node information for fix script
echo "$TARGET_NODE" > /tmp/odf-target-node.txt

# Remove ODF storage label from target node
oc label node/$TARGET_NODE cluster.ocs.openshift.io/openshift-storage- >/dev/null 2>&1

# Clean up ODF pods on the target node
oc get pods -n openshift-storage -o wide | grep "$TARGET_NODE" | awk '{print $1}' | while read pod; do
    if [ ! -z "$pod" ]; then
        oc delete pod $pod -n openshift-storage --force --grace-period=0 >/dev/null 2>&1
    fi
done

