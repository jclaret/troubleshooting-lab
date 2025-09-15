#!/bin/bash

# System Fix Script
# This script restores system configuration

# Read the saved target node name
if [ -f /tmp/odf-target-node.txt ]; then
    TARGET_NODE=$(cat /tmp/odf-target-node.txt)
    
    # Verify the target node exists and has ODF storage label
    if oc get node $TARGET_NODE >/dev/null 2>&1; then
        # Restore the ODF storage label
        oc label node/$TARGET_NODE cluster.ocs.openshift.io/openshift-storage=""
        
        # Wait for ODF pods to be scheduled on the restored node
        echo "Waiting for ODF services to be restored on node $TARGET_NODE..."
        sleep 30
        
        # Verify MON and OSD pods are running on the restored node
        MON_PODS=$(oc get pods -n openshift-storage -l app=rook-ceph-mon -o wide --no-headers | grep $TARGET_NODE | wc -l)
        OSD_PODS=$(oc get pods -n openshift-storage -l app=rook-ceph-osd -o wide --no-headers | grep $TARGET_NODE | wc -l)
        
        if [ $MON_PODS -gt 0 ] && [ $OSD_PODS -gt 0 ]; then
            echo "ODF services successfully restored on node $TARGET_NODE"
        else
            echo "Warning: ODF services may not be fully restored on node $TARGET_NODE"
        fi
    else
        echo "Error: Target node $TARGET_NODE not found"
        exit 1
    fi
else
    echo "Error: Target node information not found"
    exit 1
fi
