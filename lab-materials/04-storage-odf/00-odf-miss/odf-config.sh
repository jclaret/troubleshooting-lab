#!/bin/bash

# System Configuration Script
# This script applies system configuration changes

# Find nodes with active rook-ceph-mon pods
MON_NODES=$(oc get pods -n openshift-storage -l app=rook-ceph-mon -o wide --no-headers | grep Running | awk '{print $7}' | sort -u)

if [ -z "$MON_NODES" ]; then
    exit 1
fi

# Find nodes with active rook-ceph-osd pods
OSD_NODES=$(oc get pods -n openshift-storage -l app=rook-ceph-osd -o wide --no-headers | grep Running | awk '{print $7}' | sort -u)

if [ -z "$OSD_NODES" ]; then
    exit 1
fi

# Find nodes that have both MON and OSD pods (exclude arbiter node)
TARGET_NODES=$(comm -12 <(echo "$MON_NODES" | sort) <(echo "$OSD_NODES" | sort))

if [ -z "$TARGET_NODES" ]; then
    exit 1
fi

# Select the first node that has both MON and OSD pods
TARGET_NODE=$(echo "$TARGET_NODES" | head -1)

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

