#!/bin/bash

# System Configuration Script
# This script applies system configuration changes

# Find nodes with both MON and OSD pods running
MON_NODES=$(oc get pods -n openshift-storage -l app=rook-ceph-mon -o wide --no-headers | grep Running | awk '{print $7}' | sort -u)
OSD_NODES=$(oc get pods -n openshift-storage -l app=rook-ceph-osd -o wide --no-headers | grep Running | awk '{print $7}' | sort -u)

# Find intersection of nodes that have both MON and OSD pods
TARGET_NODES=$(comm -12 <(echo "$MON_NODES" | sort) <(echo "$OSD_NODES" | sort))

if [ -z "$TARGET_NODES" ]; then
    exit 1
fi

# Select the first node that has both MON and OSD pods
TARGET_NODE=$(echo "$TARGET_NODES" | head -1)

# Save target node information for fix script
echo "$TARGET_NODE" > /tmp/odf-issue-node.txt

# Execute shutdown via debug session
oc debug node/$TARGET_NODE -- chroot /host shutdown -h 1 >/dev/null 2>&1
