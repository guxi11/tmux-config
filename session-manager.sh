#!/bin/bash
# AI对话会话管理器
# 提供会话查看、删除、恢复等功能

SESSION_DATA_DIR="$HOME/.tmux/ai-sessions"
SESSION_CONFIG="$SESSION_DATA_DIR/config.json"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 加载配置
load_config() {
    if [[ -f "$SESSION_CONFIG" ]]; then
        source "$SESSION_CONFIG"
    else
        # 默认配置
        MAX_SESSIONS=100
        AUTO_SAVE_INTERVAL=300
        ENABLE_NOTIFICATIONS=true
    fi
}

# 显示会话详情
show_session_details() {
    local session_id="$1"
    local session_file="$SESSION_DATA_DIR/$session_id.session"
    
    if [[ ! -f "$session_file" ]]; then
        echo -e "${RED}错误: 会话文件不存在${NC}"
        return 1
    fi
    
    echo -e "${CYAN}=== AI对话会话详情 ===${NC}"
    echo -e "会话ID: $session_id"
    echo
    
    # 显示会话内容（过滤掉元数据行）
    cat "$session_file" | head -30

# 删除会话
delete_session() {
    local session_id="$1"
    local session_file="$SESSION_DATA_DIR/$session_id.session"
    
    if [[ ! -f "$session_file" ]]; then
        echo -e "${RED}错误: 会话文件不存在${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}确定要删除会话 '$session_id' 吗？(y/N)${NC}"
    read -r confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm "$session_file"
        echo -e "${GREEN}会话已删除${NC}"
    else
        echo -e "${BLUE}删除操作已取消${NC}"
    fi
}

# 恢复会话到新窗口
restore_session() {
    local session_id="$1"
    local session_file="$SESSION_DATA_DIR/$session_id.session"
    
    if [[ ! -f "$session_file" ]]; then
        echo -e "${RED}错误: 会话文件不存在${NC}"
        return 1
    fi
    
    # 创建新窗口并加载会话内容
    local window_name="ai-session-$session_id"
    
    # 在新窗口中显示会话内容
    echo -e "${CYAN}恢复会话: $session_id${NC}"
    cat "$session_file"

# 清理旧会话
cleanup_old_sessions() {
    local max_sessions=${MAX_SESSIONS:-100}
    local session_files=($(ls -t "$SESSION_DATA_DIR"/*.session 2>/dev/null))
    
    if [[ ${#session_files[@]} -gt $max_sessions ]]; then
        local files_to_delete=${#session_files[@]}-$max_sessions
        echo -e "${YELLOW}清理 $files_to_delete 个旧会话...${NC}"
        
        for ((i=max_sessions; i<${#session_files[@]}; i++)); do
            rm "${session_files[$i]}"
            echo "删除: $(basename "${session_files[$i]}")"
        done
        echo -e "${GREEN}清理完成${NC}"
    else
        echo -e "${BLUE}无需清理，当前会话数量: ${#session_files[@]}${NC}"
    fi
}

# 导出会话
export_session() {
    local session_id="$1"
    local session_file="$SESSION_DATA_DIR/$session_id.session"
    local export_format="${2:-txt}"
    
    if [[ ! -f "$session_file" ]]; then
        echo -e "${RED}错误: 会话文件不存在${NC}"
        return 1
    fi
    
    local export_file="$SESSION_DATA_DIR/${session_id}.${export_format}"
    
    case "$export_format" in
        "txt")
            cp "$session_file" "$export_file"
            ;;
        "md")
            echo "# AI对话会话: $session_id" > "$export_file"
            echo "" >> "$export_file"
            cat "$session_file" >> "$export_file"
            ;;
        *)
            echo -e "${RED}不支持的导出格式: $export_format${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}会话已导出到: $export_file${NC}"
}

# 主菜单
show_menu() {
    echo -e "${CYAN}=== AI对话会话管理器 ===${NC}"
    echo "1. 查看会话列表"
    echo "2. 查看会话详情"
    echo "3. 删除会话"
    echo "4. 恢复会话"
    echo "5. 导出会话"
    echo "6. 清理旧会话"
    echo "7. 退出"
    echo
    echo -n "请选择操作 (1-7): "
}

# 主函数
main() {
    load_config
    
    # 确保数据目录存在
    mkdir -p "$SESSION_DATA_DIR"
    
    while true; do
        show_menu
        read -r choice
        
        case "$choice" in
            1)
                # 显示会话列表
                bash "$(dirname "$0")/session-list.sh"
                ;;
            2)
                echo -n "请输入会话ID: "
                read -r session_id
                show_session_details "$session_id"
                ;;
            3)
                echo -n "请输入要删除的会话ID: "
                read -r session_id
                delete_session "$session_id"
                ;;
            4)
                echo -n "请输入要恢复的会话ID: "
                read -r session_id
                restore_session "$session_id"
                ;;
            5)
                echo -n "请输入要导出的会话ID: "
                read -r session_id
                echo -n "导出格式 (txt/json/md, 默认txt): "
                read -r export_format
                export_session "$session_id" "${export_format:-txt}"
                ;;
            6)
                cleanup_old_sessions
                ;;
            7)
                echo -e "${GREEN}退出会话管理器${NC}"
                break
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
        
        echo
        echo "按回车键继续..."
        read -r
    done
}

# 如果直接运行脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi