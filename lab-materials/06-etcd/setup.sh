#!/bin/bash

# System Configuration Script
# This script applies system configuration changes

echo "Applying system configuration changes..."

# Deploy the exercise scenario
oc apply -k . >/dev/null 2>&1

echo "Configuration changes applied successfully"
