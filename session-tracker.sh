#!/bin/bash
# AI对话会话跟踪器 - 自动跟踪和记录AI对话会话

SESSION_DATA_DIR="$HOME/.config/tmux-ai-sessions"
CONFIG_FILE="$SESSION_DATA_DIR/config"
CURRENT_SESSION_FILE="$SESSION_DATA_DIR/current_session"

# 创建必要的目录结构
mkdir -p "$SESSION_DATA_DIR/sessions"

# 加载配置
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# 默认配置
SESSION_TIMEOUT=${SESSION_TIMEOUT:-3600}  # 1小时超时
MAX_SESSIONS=${MAX_SESSIONS:-100}
AUTO_CLEANUP=${AUTO_CLEANUP:-true}

# 工具函数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SESSION_DATA_DIR/tracker.log"
}

get_session_id() {
    echo "${TMUX_PANE:-$(date +%s%N)}"
}

# 开始新会话
start_session() {
    local session_id="$(get_session_id)"
    local session_file="$SESSION_DATA_DIR/sessions/${session_id}.json"
    
    cat > "$session_file" << EOF
{
    "id": "$session_id",
    "start_time": "$(date -Iseconds)",
    "status": "active",
    "title": "${1:-Untitled Session}",
    "pane_id": "${TMUX_PANE:-}",
    "window_id": "${TMUX_WINDOW:-}",
    "session_name": "${TMUX:-}",
    "messages": []
}
EOF
    
    echo "$session_id" > "$CURRENT_SESSION_FILE"
    log_message "Started new session: $session_id"
    echo "$session_id"
}

# 添加消息到当前会话
add_message() {
    local role="$1"
    local content="$2"
    
    if [ -f "$CURRENT_SESSION_FILE" ]; then
        local session_id="$(cat $CURRENT_SESSION_FILE)"
        local session_file="$SESSION_DATA_DIR/sessions/${session_id}.json"
        
        if [ -f "$session_file" ]; then
            local temp_file="$(mktemp)"
            jq --arg role "$role" --arg content "$content" --arg timestamp "$(date -Iseconds)" '
                .messages += [{
                    "role": $role,
                    "content": $content,
                    "timestamp": $timestamp
                }]
            ' "$session_file" > "$temp_file" && mv "$temp_file" "$session_file"
            
            log_message "Added message to session $session_id: $role"
        fi
    fi
}

# 结束当前会话
end_session() {
    if [ -f "$CURRENT_SESSION_FILE" ]; then
        local session_id="$(cat $CURRENT_SESSION_FILE)"
        local session_file="$SESSION_DATA_DIR/sessions/${session_id}.json"
        
        if [ -f "$session_file" ]; then
            local temp_file="$(mktemp)"
            jq '.status = "completed" | .end_time = "'$(date -Iseconds)'"' "$session_file" > "$temp_file" && mv "$temp_file" "$session_file"
            
            rm -f "$CURRENT_SESSION_FILE"
            log_message "Ended session: $session_id"
        fi
    fi
}

# 清理过期会话
cleanup_sessions() {
    if [ "$AUTO_CLEANUP" = "true" ]; then
        local cutoff_time="$(date -d "-$SESSION_TIMEOUT seconds" +%s)"
        
        for session_file in "$SESSION_DATA_DIR/sessions"/*.json; do
            if [ -f "$session_file" ]; then
                local session_time="$(jq -r '.start_time' "$session_file" | xargs -I {} date -d {} +%s 2>/dev/null || echo 0)"
                if [ "$session_time" -lt "$cutoff_time" ]; then
                    rm -f "$session_file"
                    log_message "Cleaned up expired session: $(basename $session_file)"
                fi
            fi
        done
    fi
}

# 获取会话列表
list_sessions() {
    echo "Active Sessions:"
    echo "==============="
    for session_file in "$SESSION_DATA_DIR/sessions"/*.json; do
        if [ -f "$session_file" ]; then
            local status="$(jq -r '.status' "$session_file")"
            local title="$(jq -r '.title' "$session_file")"
            local start_time="$(jq -r '.start_time' "$session_file")"
            
            if [ "$status" = "active" ]; then
                echo "● $title ($start_time)"
            fi
        fi
    done
    
    echo -e "\nCompleted Sessions:"
    echo "=================="
    for session_file in "$SESSION_DATA_DIR/sessions"/*.json; do
        if [ -f "$session_file" ]; then
            local status="$(jq -r '.status' "$session_file")"
            local title="$(jq -r '.title' "$session_file")"
            local start_time="$(jq -r '.start_time' "$session_file")"
            
            if [ "$status" = "completed" ]; then
                echo "✓ $title ($start_time)"
            fi
        fi
    done
}

# 显示会话详情
show_session() {
    local session_id="$1"
    local session_file="$SESSION_DATA_DIR/sessions/${session_id}.json"
    
    if [ -f "$session_file" ]; then
        jq '.' "$session_file"
    else
        echo "Session not found: $session_id"
    fi
}

# 删除会话
delete_session() {
    local session_id="$1"
    local session_file="$SESSION_DATA_DIR/sessions/${session_id}.json"
    
    if [ -f "$session_file" ]; then
        rm -f "$session_file"
        log_message "Deleted session: $session_id"
        echo "Session deleted: $session_id"
    else
        echo "Session not found: $session_id"
    fi
}

# 主函数
main() {
    case "$1" in
        start)
            start_session "$2"
            ;;
        add)
            add_message "$2" "$3"
            ;;
        end)
            end_session
            ;;
        list)
            list_sessions
            ;;
        show)
            show_session "$2"
            ;;
        delete)
            delete_session "$2"
            ;;
        cleanup)
            cleanup_sessions
            ;;
        *)
            echo "Usage: $0 {start|add|end|list|show|delete|cleanup}"
            echo "  start [title]    - Start new session"
            echo "  add role content - Add message to current session"
            echo "  end              - End current session"
            echo "  list             - List all sessions"
            echo "  show session_id  - Show session details"
            echo "  delete session_id - Delete session"
            echo "  cleanup          - Cleanup expired sessions"
            ;;
    esac
}

# 如果直接执行脚本，调用主函数
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi