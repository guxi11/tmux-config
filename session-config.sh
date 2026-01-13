#!/bin/bash

# AI Session Manager Configuration
# This file contains configuration settings for the AI session manager

# Session storage directory
SESSION_DIR="$HOME/.tmux/ai-sessions"
SESSION_LOG="$SESSION_DIR/sessions.log"
CONFIG_FILE="$SESSION_DIR/config.conf"

# Default configuration values
MAX_SESSIONS=100
SESSION_TIMEOUT=86400  # 24 hours in seconds
AUTO_CLEANUP=true
ENABLE_NOTIFICATIONS=true
SESSION_PREFIX="ai-session-"

# Create session directory if it doesn't exist
mkdir -p "$SESSION_DIR"

# Load user configuration if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Function to save configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# AI Session Manager Configuration
# Generated on $(date)

MAX_SESSIONS=$MAX_SESSIONS
SESSION_TIMEOUT=$SESSION_TIMEOUT
AUTO_CLEANUP=$AUTO_CLEANUP
ENABLE_NOTIFICATIONS=$ENABLE_NOTIFICATIONS
SESSION_PREFIX="$SESSION_PREFIX"
EOF
}

# Initialize config file if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    save_config
fi

# Session status definitions
STATUS_ACTIVE="active"
STATUS_COMPLETED="completed"
STATUS_ARCHIVED="archived"
STATUS_FAILED="failed"