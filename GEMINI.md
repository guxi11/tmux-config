# tmux-config Project Documentation

## Project Overview

This is a personal tmux configuration repository for managing and versioning tmux terminal multiplexer settings. Tmux is a terminal multiplexer that allows multiple terminal sessions to be accessed and controlled from a single screen.

**Project Type:** Configuration repository for terminal multiplexer (tmux)

**Purpose:** Centralized management of tmux configuration files, themes, and plugins for consistent terminal environment setup across different machines.

## Repository Structure

Current files in the repository:

- `.tmux.conf` - Main tmux configuration file (hard-linked to `~/.tmux.conf`)
- `GEMINI.md` - This documentation file

Future additions may include:
- Plugin management files (TPM - Tmux Plugin Manager)
- Theme files and custom scripts
- Installation/setup scripts

## Expected Configuration Files

When developed, this repository should contain:

### Core Configuration
- `.tmux.conf` - Main tmux configuration file
- `tmux.conf.local` - Local overrides (optional)

### Plugin Management
- `.tmux/plugins/` - Directory for tmux plugins (managed by TPM)
- Plugin configuration in `.tmux.conf`

### Scripts and Utilities
- Installation scripts for easy setup
- Backup/restore scripts for configuration
- Custom keybinding and theme scripts

## Development Setup

### Prerequisites
- tmux installed on the system
- Git for version control
- Optional: Tmux Plugin Manager (TPM) for plugin management

### Installation Process

This repository uses hard links to maintain a single copy of the configuration file that exists in both the repository and your home directory. Changes made in either location will be reflected in both.

```bash
# Clone the repository
git clone git@github.com:guxi11/tmux-config.git
cd tmux-config

# Create hard link to tmux configuration (already done during setup)
# ln /Users/zyy/develop/Guxi11/tmux-config/.tmux.conf ~/.tmux.conf

# Reload tmux configuration (inside tmux session)
tmux source-file ~/.tmux.conf

# Or restart tmux server to apply changes
tmux kill-server
tmux

# Install plugins (if using TPM)
# Typically done by prefix + I in tmux after configuration is loaded
```

**Note:** The hard link was created during initial setup. Both files (`~/develop/Guxi11/tmux-config/.tmux.conf` and `~/.tmux.conf`) now point to the same inode, so changes to either file will affect both.

## Common tmux Configuration Areas

When developing this configuration, consider including settings for:

### Keybindings
- Custom prefix key
- Window and pane management
- Session management
- Copy/paste configurations

### Visual Customization
- Status bar configuration
- Color schemes
- Pane borders and dividers
- Font and terminal settings

### Plugin Integration
- Popular plugins like:
  - tmux-resurrect (session persistence)
  - tmux-continuum (auto-save/restore)
  - tmux-pain-control (pane navigation)
  - tmux-battery (battery status)

## Best Practices

1. **Version Control:** Keep configuration files under version control for easy rollback and synchronization
2. **Modularity:** Consider splitting configuration into multiple files for better organization
3. **Documentation:** Comment configuration options for future reference
4. **Backup:** Include scripts to backup existing configurations before applying new ones
5. **Testing:** Test configurations on different terminal emulators and systems

## Future Development Tasks

- [x] Create initial `.tmux.conf` configuration
- [x] Link configuration to home directory using hard link
- [ ] Set up Tmux Plugin Manager (TPM) integration
- [ ] Add custom keybindings and themes
- [ ] Create installation/setup scripts
- [x] Document configuration options and usage
- [ ] Add backup/restore functionality
- [ ] Test across different environments (Linux, macOS, WSL)

## Related Resources

- [Tmux GitHub Repository](https://github.com/tmux/tmux)
- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [Tmux Configuration Guide](https://github.com/tmux/tmux/wiki)

---

*This documentation will be updated as the configuration repository develops.*