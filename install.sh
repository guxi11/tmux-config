#!/bin/bash

# AI Session Manager for tmux - Installation Script
# This script installs the AI session manager plugin for tmux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    print_error "tmux is not installed. Please install tmux first."
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create necessary directories
print_status "Creating directories..."
mkdir -p ~/.tmux/plugins/ai-session-manager
mkdir -p ~/.config/tmux-ai-sessions

# Copy files to plugin directory
print_status "Installing plugin files..."
cp "$SCRIPT_DIR/ai-session-manager.tmux" ~/.tmux/plugins/ai-session-manager/
cp "$SCRIPT_DIR/session-config.sh" ~/.tmux/plugins/ai-session-manager/
cp "$SCRIPT_DIR/session-tracker.sh" ~/.tmux/plugins/ai-session-manager/
cp "$SCRIPT_DIR/session-list.sh" ~/.tmux/plugins/ai-session-manager/
cp "$SCRIPT_DIR/session-manager.sh" ~/.tmux/plugins/ai-session-manager/

# Make scripts executable
chmod +x ~/.tmux/plugins/ai-session-manager/*.sh

# Create session data directory
mkdir -p ~/.config/tmux-ai-sessions/data

# Create sample configuration if it doesn't exist
if [[ ! -f ~/.config/tmux-ai-sessions/config ]]; then
    cat > ~/.config/tmux-ai-sessions/config << 'EOF'
# AI Session Manager Configuration
SESSION_DATA_DIR="$HOME/.config/tmux-ai-sessions/data"
SESSION_HISTORY_SIZE=100
AUTO_TRACK_SESSIONS=true
ENABLE_NOTIFICATIONS=true
EOF
    print_status "Created default configuration file"
fi

# Check if TPM (Tmux Plugin Manager) is installed
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    print_warning "Tmux Plugin Manager (TPM) is not installed."
    echo "You can install TPM by running:"
    echo "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    echo ""
    echo "After installing TPM, add the following line to your ~/.tmux.conf:"
    echo "set -g @plugin 'tmux-plugins/tpm'"
    echo "set -g @plugin '~/develop/Guxi11/tmux-config'"
    echo ""
else
    print_status "TPM is already installed"
fi

# Update tmux configuration
TMUX_CONF="$HOME/.tmux.conf"
if [[ -f "$TMUX_CONF" ]]; then
    # Check if plugin is already configured
    if ! grep -q "ai-session-manager" "$TMUX_CONF"; then
        print_status "Adding plugin configuration to ~/.tmux.conf"
        cat >> "$TMUX_CONF" << 'EOF'

# AI Session Manager Plugin
set -g @plugin 'ai-session-manager'
set -g @ai-session-data-dir "$HOME/.config/tmux-ai-sessions/data"
set -g @ai-session-history-size 100
set -g @ai-session-auto-track true

# Keybindings for AI Session Manager
bind A display-popup -E "$HOME/.tmux/plugins/ai-session-manager/session-list.sh"
bind C-a display-popup -E "$HOME/.tmux/plugins/ai-session-manager/session-manager.sh"
EOF
        print_success "Plugin configuration added to ~/.tmux.conf"
    else
        print_status "Plugin configuration already exists in ~/.tmux.conf"
    fi
else
    print_warning "~/.tmux.conf not found. Creating a new one..."
    cat > "$TMUX_CONF" << 'EOF'
# Basic tmux configuration
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# AI Session Manager Plugin
set -g @plugin 'ai-session-manager'
set -g @ai-session-data-dir "$HOME/.config/tmux-ai-sessions/data"
set -g @ai-session-history-size 100
set -g @ai-session-auto-track true

# Keybindings for AI Session Manager
bind A display-popup -E "$HOME/.tmux/plugins/ai-session-manager/session-list.sh"
bind C-a display-popup -E "$HOME/.tmux/plugins/ai-session-manager/session-manager.sh"

# Initialize TPM (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF
    print_success "Created new ~/.tmux.conf with plugin configuration"
fi

# Instructions for manual installation (without TPM)
print_status ""
print_success "Installation completed!"
print_status ""
print_status "To use the plugin:"
print_status "1. Reload tmux configuration: tmux source-file ~/.tmux.conf"
print_status "2. Use keybindings:"
print_status "   - Prefix + A: Show AI session list"
print_status "   - Prefix + C-a: Open session manager"
print_status ""
print_status "If using TPM, install plugins with: Prefix + I (capital i)"
print_status ""
print_status "Session data will be stored in: ~/.config/tmux-ai-sessions/data/"
print_status "Configuration file: ~/.config/tmux-ai-sessions/config"