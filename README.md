# AI对话会话管理器 - tmux插件

一个功能强大的tmux插件，用于管理AI对话会话，包括已完成的会话和进行中的会话。

## 功能特性

- 📋 **会话列表**：显示所有AI对话会话，包括已完成和进行中的会话
- 🔍 **会话详情**：查看每个会话的详细对话内容
- 🗑️ **会话管理**：删除不需要的会话
- 🔄 **会话恢复**：恢复已完成的会话继续对话
- 📊 **会话统计**：显示会话数量、时间统计等信息
- ⚡ **实时跟踪**：自动跟踪和记录AI对话会话

## 安装

### 方法1：手动安装

1. 克隆此仓库：
```bash
git clone git@github.com:guxi11/tmux-config.git
cd tmux-config
```

2. 运行安装脚本：
```bash
chmod +x install.sh
./install.sh
```

3. 重新加载tmux配置：
```bash
tmux source-file ~/.tmux.conf
```

### 方法2：使用TPM（Tmux Plugin Manager）

如果您使用TPM，可以将此插件添加到您的tmux配置中：

```tmux
set -g @plugin 'guxi11/tmux-ai-session-manager'
```

## 使用方法

### 快捷键

- `C-a A` - 打开AI会话管理器主界面
- `C-a L` - 快速查看会话列表
- `C-a T` - 开始新的AI对话会话跟踪

### 基本操作

1. **开始跟踪新会话**：
   - 按 `C-a T` 开始跟踪当前窗口的AI对话
   - 插件会自动检测AI对话并记录内容

2. **查看会话列表**：
   - 按 `C-a L` 查看所有会话
   - 使用方向键选择会话
   - 按回车查看会话详情

3. **管理会话**：
   - 在会话列表界面按 `d` 删除会话
   - 按 `r` 恢复会话继续对话
   - 按 `q` 退出界面

## 配置

插件配置文件位于 `~/.config/tmux-ai-session/session-config.sh`，您可以自定义以下设置：

- `AI_SESSION_DIR`：会话数据存储目录
- `SESSION_TIMEOUT`：会话超时时间（秒）
- `MAX_SESSIONS`：最大保存会话数量
- `ENABLE_AUTO_TRACKING`：是否启用自动跟踪

## 文件结构

```
tmux-config/
├── ai-session-manager.tmux    # 主插件文件
├── session-config.sh          # 配置文件
├── session-tracker.sh          # 会话跟踪器
├── session-list.sh            # 会话列表显示
├── session-manager.sh         # 会话管理功能
├── install.sh                 # 安装脚本
└── README.md                  # 说明文档
```

## 数据存储

会话数据存储在 `~/.config/tmux-ai-session/` 目录下：

- `sessions/` - 会话数据文件
- `active/` - 进行中的会话
- `completed/` - 已完成的会话
- `config` - 配置文件

## 依赖

- tmux 2.0+
- bash 4.0+
- grep, sed, awk 等基本Unix工具

## 故障排除

如果插件无法正常工作：

1. 检查tmux版本：`tmux -V`
2. 确认插件文件有执行权限：`chmod +x *.sh`
3. 查看错误日志：`tail -f ~/.config/tmux-ai-session/error.log`
4. 重新加载配置：`tmux source-file ~/.tmux.conf`

## 贡献

欢迎提交Issue和Pull Request来改进这个插件！

## 许可证

MIT License
