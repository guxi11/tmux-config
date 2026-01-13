#!/bin/bash
# AI对话会话列表显示脚本

SESSION_DATA_DIR="$HOME/.tmux/ai-sessions"
CONFIG_FILE="$HOME/.tmux/ai-session-config"

# 加载配置
source "$CONFIG_FILE" 2>/dev/null || {
    echo "配置文件不存在，使用默认配置"
}

# 默认配置
SESSION_DATA_DIR="${SESSION_DATA_DIR:-$HOME/.tmux/ai-sessions}"
MAX_SESSIONS_TO_SHOW="${MAX_SESSIONS_TO_SHOW:-20}"

# 创建会话目录
mkdir -p "$SESSION_DATA_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 显示会话列表
show_session_list() {
    local filter="$1"
    local sessions=()
    
    # 获取所有会话文件
    if [[ -d "$SESSION_DATA_DIR" ]]; then
        while IFS= read -r -d '' file; do
            sessions+=("$file")
        done < <(find "$SESSION_DATA_DIR" -name "*.session" -type f -print0 2>/dev/null)
    fi
    
    # 按修改时间排序（最新的在前）
    sessions=($(printf '%s\n' "${sessions[@]}" | xargs -I {} sh -c 'echo "$(stat -f %m {}) {}"' | sort -nr | cut -d' ' -f2-))
    
    # 限制显示数量
    sessions=("${sessions[@]:0:$MAX_SESSIONS_TO_SHOW}")
    
    echo -e "${CYAN}=== AI对话会话管理器 ===${NC}"
    echo -e "${YELLOW}快捷键:${NC}"
    echo -e "  ${GREEN}数字${NC} - 查看会话详情"
    echo -e "  ${GREEN}d+数字${NC} - 删除会话"
    echo -e "  ${GREEN}r+数字${NC} - 恢复会话到新窗口"
    echo -e "  ${GREEN}q${NC} - 退出"
    echo -e "${CYAN}========================${NC}"
    echo
    
    if [[ ${#sessions[@]} -eq 0 ]]; then
        echo -e "${YELLOW}暂无AI对话会话记录${NC}"
        return
    fi
    
    local index=1
    for session_file in "${sessions[@]}"; do
        local session_name=$(basename "$session_file" .session)
        local timestamp=$(stat -f %m "$session_file" 2>/dev/null || echo "0")
        local date_str=$(date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "未知时间")
        
        # 读取会话状态
        local status="进行中"
        if grep -q "# Status: completed" "$session_file" 2>/dev/null; then
            status="已完成"
        fi
        
        # 读取会话标题（第一行）
        local title=$(head -1 "$session_file" 2>/dev/null | sed 's/^# AI Session: //')
        title="${title:-无标题会话}"
        
        # 根据状态设置颜色
        local status_color="$GREEN"
        if [[ "$status" == "进行中" ]]; then
            status_color="$YELLOW"
        fi
        
        # 根据过滤器显示
        if [[ -z "$filter" ]] || [[ "$status" == "$filter" ]]; then
            echo -e "${BLUE}[$index]${NC} ${WHITE}$title${NC}"
            echo -e "     状态: ${status_color}$status${NC}"
            echo -e "     时间: $date_str"
            echo -e "     文件: $session_name"
            echo
            ((index++))
        fi
    done
}

# 查看会话详情
view_session_detail() {
    local session_num="$1"
    local sessions=()
    
    # 获取所有会话文件
    if [[ -d "$SESSION_DATA_DIR" ]]; then
        while IFS= read -r -d '' file; do
            sessions+=("$file")
        done < <(find "$SESSION_DATA_DIR" -name "*.session" -type f -print0 2>/dev/null)
    fi
    
    # 按修改时间排序
    sessions=($(printf '%s\n' "${sessions[@]}" | xargs -I {} sh -c 'echo "$(stat -f %m {}) {}"' | sort -nr | cut -d' ' -f2-))
    sessions=("${sessions[@]:0:$MAX_SESSIONS_TO_SHOW}")
    
    if [[ $session_num -lt 1 ]] || [[ $session_num -gt ${#sessions[@]} ]]; then
        echo -e "${RED}无效的会话编号${NC}"
        return 1
    fi
    
    local session_file="${sessions[$((session_num-1))]}"
    local session_name=$(basename "$session_file" .session)
    
    echo -e "${CYAN}=== 会话详情: $session_name ===${NC}"
    echo
    
    # 显示会话内容（过滤掉元数据行）
    grep -v "^# " "$session_file" | head -50
    
    local total_lines=$(wc -l < "$session_file" 2>/dev/null || echo "0")
    if [[ $total_lines -gt 50 ]]; then
        echo -e "${YELLOW}[...] 还有 $((total_lines-50)) 行内容未显示${NC}"
    fi
    
    echo
    echo -e "${YELLOW}按任意键继续...${NC}"
    read -n 1
}

# 删除会话
delete_session() {
    local session_num="$1"
    local sessions=()
    
    # 获取所有会话文件
    if [[ -d "$SESSION_DATA_DIR" ]]; then
        while IFS= read -r -d '' file; do
            sessions+=("$file")
        done < <(find "$SESSION_DATA_DIR" -name "*.session" -type f -print0 2>/dev/null)
    fi
    
    # 按修改时间排序
    sessions=($(printf '%s\n' "${sessions[@]}" | xargs -I {} sh -c 'echo "$(stat -f %m {}) {}"' | sort -nr | cut -d' ' -f2-))
    sessions=("${sessions[@]:0:$MAX_SESSIONS_TO_SHOW}")
    
    if [[ $session_num -lt 1 ]] || [[ $session_num -gt ${#sessions[@]} ]]; then
        echo -e "${RED}无效的会话编号${NC}"
        return 1
    fi
    
    local session_file="${sessions[$((session_num-1))]}"
    local session_name=$(basename "$session_file" .session)
    
    echo -e "${YELLOW}确定要删除会话 '$session_name' 吗？ (y/N): ${NC}"
    read -n 1 confirm
    echo
    
    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        rm -f "$session_file"
        echo -e "${GREEN}会话已删除${NC}"
    else
        echo -e "${YELLOW}取消删除${NC}"
    fi
}

# 恢复会话到新窗口
restore_session() {
    local session_num="$1"
    local sessions=()
    
    # 获取所有会话文件
    if [[ -d "$SESSION_DATA_DIR" ]]; then
        while IFS= read -r -d '' file; do
            sessions+=("$file")
        done < <(find "$SESSION_DATA_DIR" -name "*.session" -type f -print0 2>/dev/null)
    fi
    
    # 按修改时间排序
    sessions=($(printf '%s\n' "${sessions[@]}" | xargs -I {} sh -c 'echo "$(stat -f %m {}) {}"' | sort -nr | cut -d' ' -f2-))
    sessions=("${sessions[@]:0:$MAX_SESSIONS_TO_SHOW}")
    
    if [[ $session_num -lt 1 ]] || [[ $session_num -gt ${#sessions[@]} ]]; then
        echo -e "${RED}无效的会话编号${NC}"
        return 1
    fi
    
    local session_file="${sessions[$((session_num-1))]}"
    local session_name=$(basename "$session_file" .session)
    
    # 创建恢复脚本临时文件
    local temp_script=$(mktemp)
    
    cat > "$temp_script" << EOF
#!/bin/bash
echo "=== 恢复AI对话会话: $session_name ==="
echo
cat "$session_file"
echo
echo "=== 会话恢复完成 ==="
echo "按Ctrl+D退出"
EOF
    
    chmod +x "$temp_script"
    
    # 在新窗口中打开会话
    tmux new-window -n "AI-$session_name" "$temp_script; rm -f \"$temp_script\""
    
    echo -e "${GREEN}会话已在新窗口中恢复${NC}"
}

# 主函数
main() {
    local action="$1"
    local param="$2"
    
    case "$action" in
        "list")
            show_session_list "$param"
            ;;
        "view")
            view_session_detail "$param"
            ;;
        "delete")
            delete_session "$param"
            ;;
        "restore")
            restore_session "$param"
            ;;
        *)
            show_session_list
            echo -e "${YELLOW}输入操作 (数字/d数字/r数字/q): ${NC}"
            read -n 2 input
            echo
            
            case "$input" in
                [0-9])
                    view_session_detail "$input"
                    ;;
                d[0-9])
                    delete_session "${input:1}"
                    ;;
                r[0-9])
                    restore_session "${input:1}"
                    ;;
                q|Q)
                    exit 0
                    ;;
                *)
                    echo -e "${RED}无效输入${NC}"
                    ;;
            esac
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi