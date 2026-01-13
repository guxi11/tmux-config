#!/bin/bash
# 增强版会话列表 - 显示所有tmux会话和AI会话

SESSION_DATA_DIR="$HOME/.tmux/ai-sessions"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 检测会话类型
detect_session_type() {
    local session_name="$1"
    
    # 检测gemini相关会话
    if [[ "$session_name" == *"gemini"* ]] || [[ "$session_name" == *"gpt"* ]] || [[ "$session_name" == *"ai"* ]]; then
        echo "gemini"
        return
    fi
    
    # 检测claude相关会话
    if [[ "$session_name" == *"claude"* ]] || [[ "$session_name" == *"anthropic"* ]]; then
        echo "claude"
        return
    fi
    
    # 检测邮件相关会话
    if [[ "$session_name" == *"mail"* ]] || [[ "$session_name" == *"email"* ]]; then
        echo "mail"
        return
    fi
    
    # 检测开发相关会话
    if [[ "$session_name" == *"dev"* ]] || [[ "$session_name" == *"code"* ]] || [[ "$session_name" == *"work"* ]]; then
        echo "development"
        return
    fi
    
    echo "general"
}

# 获取会话类型图标和颜色
get_session_icon() {
    local session_type="$1"
    
    case "$session_type" in
        "gemini")
            echo -e "${YELLOW}🤖${NC}"
            ;;
        "claude")
            echo -e "${BLUE}🧠${NC}"
            ;;
        "mail")
            echo -e "${RED}📧${NC}"
            ;;
        "development")
            echo -e "${GREEN}💻${NC}"
            ;;
        *)
            echo -e "${WHITE}📋${NC}"
            ;;
    esac
}

# 显示所有tmux会话
show_tmux_sessions() {
    echo -e "${CYAN}=== TMUX会话列表 ===${NC}"
    echo
    
    # 获取所有tmux会话
    local sessions=$(tmux list-sessions -F '#{session_name}:#{session_created}:#{session_attached}:#{session_windows}' 2>/dev/null)
    
    if [[ -z "$sessions" ]]; then
        echo -e "${YELLOW}没有找到tmux会话${NC}"
        return
    fi
    
    local count=0
    while IFS=':' read -r name created attached windows; do
        ((count++))
        
        # 转换时间戳为可读格式
        local created_date=$(date -r "$created" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "未知时间")
        
        # 检测会话类型
        local session_type=$(detect_session_type "$name")
        local icon=$(get_session_icon "$session_type")
        
        # 状态指示
        local status="${GREEN}●${NC}"
        if [[ "$attached" == "0" ]]; then
            status="${YELLOW}○${NC}"
        fi
        
        echo -e "${PURPLE}[$count]${NC} $icon ${WHITE}$name${NC} $status"
        echo -e "     类型: ${BLUE}$session_type${NC}"
        echo -e "     创建: $created_date"
        echo -e "     窗口: $windows 个"
        echo -e "     状态: $([[ \"$attached\" == \"1\" ]] && echo \"已连接\" || echo \"未连接\")"
        echo
    done <<< "$sessions"
    
    echo -e "${CYAN}总计: $count 个会话${NC}"
}

# 显示AI会话
show_ai_sessions() {
    echo -e "${CYAN}=== AI对话会话 ===${NC}"
    echo
    
    local sessions=()
    
    # 获取所有AI会话文件
    if [[ -d "$SESSION_DATA_DIR" ]]; then
        while IFS= read -r -d '' file; do
            sessions+=("$file")
        done < <(find "$SESSION_DATA_DIR" -name "*.session" -type f -print0 2>/dev/null)
    fi
    
    # 按修改时间排序（最新的在前）
    sessions=($(printf '%s\n' "${sessions[@]}" | xargs -I {} sh -c 'echo "$(stat -f %m {}) {}"' | sort -nr | cut -d' ' -f2-))
    
    if [[ ${#sessions[@]} -eq 0 ]]; then
        echo -e "${YELLOW}暂无AI对话会话记录${NC}"
        return
    fi
    
    local count=0
    for session_file in "${sessions[@]}"; do
        ((count++))
        
        local session_name=$(basename "$session_file" .session)
        local timestamp=$(stat -f %m "$session_file" 2>/dev/null || echo "0")
        local date_str=$(date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "未知时间")
        
        # 读取会话状态
        local status="进行中"
        local status_color="$YELLOW"
        if grep -q "# Status: completed" "$session_file" 2>/dev/null; then
            status="已完成"
            status_color="$BLUE"
        fi
        
        # 读取会话标题（第一行）
        local title=$(head -1 "$session_file" 2>/dev/null | sed 's/^# AI Session: //')
        title="${title:-无标题会话}"
        
        echo -e "${PURPLE}[A$count]${NC} ${YELLOW}🤖${NC} ${WHITE}$title${NC}"
        echo -e "     状态: ${status_color}$status${NC}"
        echo -e "     时间: $date_str"
        echo -e "     文件: $session_name"
        echo
    done
    
    echo -e "${CYAN}总计: $count 个AI会话${NC}"
}

# 显示会话统计
show_session_stats() {
    echo -e "${CYAN}=== 会话统计 ===${NC}"
    echo
    
    # 统计tmux会话
    local tmux_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')
    tmux_count="${tmux_count:-0}"
    
    # 统计AI会话
    local ai_count=0
    if [[ -d "$SESSION_DATA_DIR" ]]; then
        ai_count=$(find "$SESSION_DATA_DIR" -name "*.session" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    echo -e "📊 TMUX会话: ${GREEN}$tmux_count${NC} 个"
    echo -e "🤖 AI会话: ${YELLOW}$ai_count${NC} 个"
    echo -e "📈 总计: ${CYAN}$((tmux_count + ai_count))${NC} 个会话"
    echo
}

# 主函数
main() {
    local mode="${1:-all}"
    
    case "$mode" in
        "tmux")
            show_tmux_sessions
            ;;
        "ai")
            show_ai_sessions
            ;;
        "stats")
            show_session_stats
            ;;
        "all"|*)
            show_session_stats
            echo
            show_tmux_sessions
            echo
            show_ai_sessions
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi