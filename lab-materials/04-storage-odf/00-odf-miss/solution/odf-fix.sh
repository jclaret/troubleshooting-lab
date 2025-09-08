#!/bin/bash

# System Fix Script
# This script restores system configuration

# Read the saved target node name
if [ -f /tmp/odf-target-node.txt ]; then
    TARGET_NODE=$(cat /tmp/odf-target-node.txt)
    
    # Restore the ODF storage label
    oc label node/$TARGET_NODE cluster.ocs.openshift.io/openshift-storage=""
else
    exit 1
fi
