#!/bin/bash

PROJECT_DIR="/Users/voha/Source/RTO Tracker/RTOTracker"
PROJECT_NAME="RTOTracker"

# Create xcodeproj using swift package
cd "$PROJECT_DIR"
swift package init --type executable --name "$PROJECT_NAME"

# We'll convert this to an app project
