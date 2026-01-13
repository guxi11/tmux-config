#!/usr/bin/env bash

# AI Session Manager for tmux
# A plugin to manage AI conversation sessions within tmux

# Default configuration
AI_SESSION_DIR="${HOME}/.tmux/ai-sessions"
AI_SESSION_LOG="${AI_SESSION_DIR}/sessions.log"
AI_SESSION_CONFIG="${AI_SESSION_DIR}/config"
AI_SESSION_MAX_HISTORY=100

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Initialize the plugin
ai_session_init() {
    # Create directories if they don't exist
    mkdir -p "${AI_SESSION_DIR}"
    
    # Initialize session log if it doesn't exist
    if [[ ! -f "${AI_SESSION_LOG}" ]]; then
        echo "# AI Session Log" > "${AI_SESSION_LOG}"
        echo "# Format: timestamp|session_id|status|title|model|tokens|duration" >> "${AI_SESSION_LOG}"
    fi
    
    # Initialize config if it doesn't exist
    if [[ ! -f "${AI_SESSION_CONFIG}" ]]; then
        echo "max_history=${AI_SESSION_MAX_HISTORY}" > "${AI_SESSION_CONFIG}"
        echo "auto_track=true" >> "${AI_SESSION_CONFIG}"
        echo "default_model=gpt-4" >> "${AI_SESSION_CONFIG}"
    fi
}

# Start a new AI session
ai_session_start() {
    local session_id="$(date +%s%N)"
    local title="${1:-Untitled Conversation}"
    local model="${2:-$(grep 'default_model' "${AI_SESSION_CONFIG}" | cut -d'=' -f2)}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Create session file
    local session_file="${AI_SESSION_DIR}/${session_id}.session"
    echo "# AI Session: ${title}" > "${session_file}"
    echo "# Model: ${model}" >> "${session_file}"
    echo "# Started: ${timestamp}" >> "${session_file}"
    echo "# Status: active" >> "${session_file}"
    echo "" >> "${session_file}"
    
    # Add to session log
    echo "${timestamp}|${session_id}|active|${title}|${model}|0|0" >> "${AI_SESSION_LOG}"
    
    # Set tmux environment variable for current session
    tmux set-environment -g AI_SESSION_ID "${session_id}"
    tmux set-environment -g AI_SESSION_TITLE "${title}"
    
    echo "Started new AI session: ${title} (ID: ${session_id})"
    echo "Session file: ${session_file}"
}

# Add message to current session
ai_session_add_message() {
    local session_id="$(tmux show-environment -g AI_SESSION_ID 2>/dev/null | cut -d'=' -f2)"
    local role="${1}"
    local content="${2}"
    
    if [[ -z "${session_id}" ]]; then
        echo "${RED}No active AI session found${NC}"
        return 1
    fi
    
    local session_file="${AI_SESSION_DIR}/${session_id}.session"
    
    if [[ ! -f "${session_file}" ]]; then
        echo "${RED}Session file not found: ${session_file}${NC}"
        return 1
    fi
    
    echo "" >> "${session_file}"
    echo "[${role}] $(date '+%Y-%m-%d %H:%M:%S')" >> "${session_file}"
    echo "${content}" >> "${session_file}"
    
    echo "Added ${role} message to session ${session_id}"
}

# End current AI session
ai_session_end() {
    local session_id="$(tmux show-environment -g AI_SESSION_ID 2>/dev/null | cut -d'=' -f2)"
    
    if [[ -z "${session_id}" ]]; then
        echo "${RED}No active AI session found${NC}"
        return 1
    fi
    
    local session_file="${AI_SESSION_DIR}/${session_id}.session"
    
    if [[ ! -f "${session_file}" ]]; then
        echo "${RED}Session file not found: ${session_file}${NC}"
        return 1
    fi
    
    # Update session file status
    sed -i.bak 's/# Status: active/# Status: completed/' "${session_file}"
    echo "" >> "${session_file}"
    echo "# Ended: $(date '+%Y-%m-%d %H:%M:%S')" >> "${session_file}"
    
    # Update session log
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    sed -i.bak "/${session_id}|active/ s/active/completed/" "${AI_SESSION_LOG}"
    
    # Clear tmux environment variables
    tmux set-environment -gu AI_SESSION_ID
    tmux set-environment -gu AI_SESSION_TITLE
    
    echo "Ended AI session: ${session_id}"
}

# List all AI sessions
ai_session_list() {
    local status_filter="${1:-all}"
    
    echo -e "${CYAN}=== AI Session List ===${NC}"
    echo -e "${BLUE}Status Filter: ${status_filter}${NC}"
    echo
    
    if [[ ! -f "${AI_SESSION_LOG}" ]]; then
        echo "${YELLOW}No session log found. Run 'ai_session_init' first.${NC}"
        return 1
    fi
    
    local count=0
    while IFS='|' read -r timestamp session_id status title model tokens duration; do
        # Skip comment lines
        if [[ "${timestamp}" == "#"* ]]; then
            continue
        fi
        
        # Filter by status
        if [[ "${status_filter}" != "all" && "${status_filter}" != "${status}" ]]; then
            continue
        fi
        
        # Color coding for status
        local status_color="${GREEN}"
        if [[ "${status}" == "active" ]]; then
            status_color="${YELLOW}"
        elif [[ "${status}" == "completed" ]]; then
            status_color="${BLUE}"
        fi
        
        echo -e "${PURPLE}${session_id}${NC}"
        echo -e "  Title: ${WHITE}${title}${NC}"
        echo -e "  Status: ${status_color}${status}${NC}"
        echo -e "  Model: ${model}"
        echo -e "  Started: ${timestamp}"
        echo -e "  Tokens: ${tokens}, Duration: ${duration}s"
        echo
        
        ((count++))
    done < "${AI_SESSION_LOG}"
    
    echo -e "${CYAN}Total sessions: ${count}${NC}"
}

# Show details of a specific session
ai_session_show() {
    local session_id="${1}"
    
    if [[ -z "${session_id}" ]]; then
        echo "${RED}Please provide a session ID${NC}"
        return 1
    fi
    
    local session_file="${AI_SESSION_DIR}/${session_id}.session"
    
    if [[ ! -f "${session_file}" ]]; then
        echo "${RED}Session not found: ${session_id}${NC}"
        return 1
    fi
    
    echo -e "${CYAN}=== AI Session Details ===${NC}"
    echo -e "${BLUE}Session ID: ${session_id}${NC}"
    echo
    cat "${session_file}"
}

# Delete a session
ai_session_delete() {
    local session_id="${1}"
    
    if [[ -z "${session_id}" ]]; then
        echo "${RED}Please provide a session ID${NC}"
        return 1
    fi
    
    local session_file="${AI_SESSION_DIR}/${session_id}.session"
    
    if [[ ! -f "${session_file}" ]]; then
        echo "${RED}Session not found: ${session_id}${NC}"
        return 1
    fi
    
    # Remove from session log
    sed -i.bak "/${session_id}/d" "${AI_SESSION_LOG}"
    
    # Delete session file
    rm "${session_file}"
    
    echo "Deleted session: ${session_id}"
}

# Interactive session manager
ai_session_manager() {
    while true; do
        clear
        echo -e "${CYAN}=== AI Session Manager ===${NC}"
        echo "1. List all sessions"
        echo "2. List active sessions"
        echo "3. List completed sessions"
        echo "4. Show session details"
        echo "5. Delete session"
        echo "6. Start new session"
        echo "7. Exit"
        echo
        read -p "Select option (1-7): " choice
        
        case $choice in
            1)
                ai_session_list all
                ;;
            2)
                ai_session_list active
                ;;
            3)
                ai_session_list completed
                ;;
            4)
                read -p "Enter session ID: " session_id
                ai_session_show "$session_id"
                ;;
            5)
                read -p "Enter session ID to delete: " session_id
                ai_session_delete "$session_id"
                ;;
            6)
                read -p "Enter session title: " title
                ai_session_start "$title"
                ;;
            7)
                break
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Auto-detect and track AI sessions
ai_session_auto_track() {
    # This function would be called periodically to detect AI sessions
    # For now, it's a placeholder for future enhancement
    echo "Auto-tracking not yet implemented"
}

# Main function
main() {
    local command="${1}"
    
    case "${command}" in
        init)
            ai_session_init
            ;;
        start)
            ai_session_start "${2}" "${3}"
            ;;
        add)
            ai_session_add_message "${2}" "${3}"
            ;;
        end)
            ai_session_end
            ;;
        list)
            ai_session_list "${2}"
            ;;
        show)
            ai_session_show "${2}"
            ;;
        delete)
            ai_session_delete "${2}"
            ;;
        manager)
            ai_session_manager
            ;;
        *)
            echo "AI Session Manager for tmux"
            echo "Usage: $0 <command> [args]"
            echo "Commands:"
            echo "  init                    - Initialize plugin"
            echo "  start <title> [model]   - Start new session"
            echo "  add <role> <content>    - Add message to current session"
            echo "  end                     - End current session"
            echo "  list [status]           - List sessions (all|active|completed)"
            echo "  show <session_id>       - Show session details"
            echo "  delete <session_id>     - Delete session"
            echo "  manager                 - Interactive session manager"
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi