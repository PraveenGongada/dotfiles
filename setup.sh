#!/usr/bin/env bash

# Dotfiles Installation Script
# A standalone installer that can be downloaded and run directly
# Usage: curl -fsSL https://raw.githubusercontent.com/PraveenGongada/dotfiles/main/setup.sh | bash
# 
# Features:
# - Idempotent: Can be run multiple times safely
# - Resumable: Continues from where it left off if interrupted
# - Safe: Creates backups before making changes
# - Configurable: Supports environment variables and flags
#
# Environment Variables:
# - DOTFILES_REPO: Override repository URL
# - DOTFILES_DIR: Override installation directory
# - SKIP_BACKUP: Set to 'true' to skip backup creation
# - FORCE_INSTALL: Set to 'true' to overwrite without prompting

# Check bash version first, before strict mode
bash_version=$(bash --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
major_version=${bash_version%%.*}

if [[ "$major_version" -lt 4 ]]; then
    echo "Error: This script requires Bash 4.0 or later for associative arrays."
    echo "Current version: $bash_version"
    echo "Please update Bash using Homebrew: brew install bash"
    echo "Or run with updated bash: /opt/homebrew/bin/bash ./setup.sh"
    exit 1
fi

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script version for compatibility tracking
SCRIPT_VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (can be overridden by environment variables)
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/PraveenGongada/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/dotfiles}"
BACKUP_DIR="${BACKUP_DIR:-${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)}"
STATE_FILE="${HOME}/.dotfiles_setup_state"
LOG_FILE="${HOME}/.dotfiles_install.log"
SKIP_BACKUP="${SKIP_BACKUP:-false}"
FORCE_INSTALL="${FORCE_INSTALL:-false}"

# Command line argument parsing
INSTALL_PACKAGES=true
VERBOSE=false

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-packages)
                INSTALL_PACKAGES=false
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Dotfiles Installation Script v${SCRIPT_VERSION}

Usage: $0 [OPTIONS]

OPTIONS:
    --no-packages     Skip package installation
    --verbose, -v     Enable verbose logging
    --force           Force overwrite without prompting
    --skip-backup     Skip backup creation
    --help, -h        Show this help message

ENVIRONMENT VARIABLES:
    DOTFILES_REPO     Override repository URL
    DOTFILES_DIR      Override installation directory
    SKIP_BACKUP       Skip backup creation (true/false)
    FORCE_INSTALL     Force overwrite without prompting (true/false)

EXAMPLES:
    # Default installation
    $0
    
    # Skip package installation only
    $0 --no-packages
    
    # Use custom repository
    DOTFILES_REPO=username/dotfiles $0
    
    # Force install without backups
    $0 --force --skip-backup

EOF
}

print_status() {
    local message="$1"
    echo -e "${BLUE}==>${NC} $message" | tee -a "$LOG_FILE"
}

print_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message" | tee -a "$LOG_FILE"
}

print_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} $message" | tee -a "$LOG_FILE"
}

print_error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: $message" >> "$LOG_FILE"
    exit 1
}

print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1" | tee -a "$LOG_FILE"
    fi
}

log_command() {
    local cmd="$1"
    print_verbose "Executing: $cmd"
    echo "$(date '+%Y-%m-%d %H:%M:%S') CMD: $cmd" >> "$LOG_FILE"
}

# Initialize logging
init_logging() {
    echo "=== Dotfiles Installation Log ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "Script Version: $SCRIPT_VERSION" >> "$LOG_FILE"
    echo "Arguments: $*" >> "$LOG_FILE"
    echo "Repository: $DOTFILES_REPO" >> "$LOG_FILE"
    echo "Directory: $DOTFILES_DIR" >> "$LOG_FILE"
    echo "====================================" >> "$LOG_FILE"
    echo
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Save installation state
save_state() {
    local step="$1"
    INSTALL_STEPS["$step"]="true"
    # Save to state file for resume capability
    for key in "${!INSTALL_STEPS[@]}"; do
        echo "$key=${INSTALL_STEPS[$key]}"
    done > "$STATE_FILE"
}

# Load installation state
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        while IFS='=' read -r key value; do
            if [[ -n "$key" && "${INSTALL_STEPS[$key]+exists}" ]]; then
                INSTALL_STEPS["$key"]="$value"
            fi
        done < "$STATE_FILE"
        print_status "Resuming previous installation..."
    fi
}

# Check if step is completed
is_step_completed() {
    [[ "${INSTALL_STEPS[$1]}" == "true" ]]
}

# Create backup of existing files
create_backup() {
    local target="$1"
    local backup_name="$2"
    
    if [[ "$SKIP_BACKUP" == "true" ]]; then
        print_verbose "Skipping backup for $backup_name"
        return
    fi
    
    if [[ -e "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_command "cp -R $target $BACKUP_DIR/$backup_name"
        if cp -R "$target" "$BACKUP_DIR/$backup_name" 2>/dev/null; then
            print_success "Backed up existing $backup_name to $BACKUP_DIR"
        else
            print_warning "Failed to backup $backup_name"
        fi
    fi
}

# Prompt user for confirmation unless force mode is enabled
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$FORCE_INSTALL" == "true" ]]; then
        print_verbose "Force mode: auto-confirming $message"
        return 0
    fi
    
    local prompt="$message [y/N]: "
    if [[ "$default" == "y" ]]; then
        prompt="$message [Y/n]: "
    fi
    
    read -p "$prompt" -r response
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}


# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only. Current OS: $OSTYPE"
    fi
    
    # Check macOS version
    local macos_version
    macos_version=$(sw_vers -productVersion)
    print_verbose "macOS version: $macos_version"
    
    # Check available disk space (require at least 1GB)
    local available_space
    available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/[^0-9]*//g')
    if [[ "$available_space" -lt 1024 ]]; then
        print_warning "Low disk space detected. Available: ${available_space}MB"
        if ! confirm_action "Continue anyway?"; then
            print_error "Installation cancelled due to low disk space"
        fi
    fi
    
    # Check internet connectivity
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        print_error "No internet connection. Please check your network and try again."
    fi
    
    print_success "System requirements check passed"
}

# Cleanup function for safe exit
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_error "Installation failed! You can:"
        echo "  1. Fix the issue and re-run the script (it will resume from where it left off)"
        echo "  2. Restore from backup: $BACKUP_DIR"
        echo "  3. Remove state file to start fresh: rm $STATE_FILE"
    fi
}

# Set trap for cleanup
trap cleanup_on_exit EXIT

# Detect OS and architecture
detect_system() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
    fi
    
    # Check if running on Apple Silicon or Intel
    if [[ $(uname -m) == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
}

# Install Homebrew if not present
install_homebrew() {
    if is_step_completed "homebrew"; then
        print_success "Homebrew already installed"
        return
    fi
    
    if ! command_exists brew; then
        print_status "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            print_error "Failed to install Homebrew"
        }
        
        # Add Homebrew to PATH
        echo 'eval "$('$HOMEBREW_PREFIX'/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
        
        if ! command_exists brew; then
            print_error "Homebrew installation failed - brew command not found"
        fi
        
        print_success "Homebrew installed successfully"
    else
        print_success "Homebrew already installed"
    fi
    
    save_state "homebrew"
}

# Clone dotfiles repository
clone_dotfiles() {
    if is_step_completed "clone_repo"; then
        print_success "Dotfiles repository already cloned"
        return
    fi
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        create_backup "$DOTFILES_DIR" "dotfiles_existing"
        rm -rf "$DOTFILES_DIR"
    fi
    
    print_status "📦 Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || {
        print_error "Failed to clone dotfiles repository"
    }
    
    print_success "Dotfiles repository cloned"
    save_state "clone_repo"
}

# Helper function to create safe symlinks
safe_symlink() {
    local source="$1"
    local target="$2"
    local app_name="$3"
    local file_name=$(basename "$target")
    
    # Create backup if target exists and is not a symlink
    if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
        create_backup "$target" "${app_name}_${file_name}"
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target")"
    
    # Create symlink
    ln -sf "$source" "$target" || {
        print_error "Failed to create symlink: $source -> $target"
    }
    print_success "$app_name $file_name symlinked"
}

# Install Homebrew packages
install_brew_packages() {
    if is_step_completed "brew_packages"; then
        print_success "Homebrew packages already installed"
        return
    fi
    
    print_status "🍺 Installing Homebrew packages from Brewfile..."
    local brewfile="$DOTFILES_DIR/homebrew/Brewfile"
    
    if [[ ! -f "$brewfile" ]]; then
        print_error "Brewfile not found at $brewfile"
    fi
    
    cd "$DOTFILES_DIR/homebrew"
    log_command "brew bundle --no-lock"
    brew bundle --no-lock || {
        print_error "Failed to install Homebrew packages"
    }
    
    # Verify stow was installed
    if ! command_exists stow; then
        print_error "GNU Stow was not installed from Brewfile"
    fi
    
    print_success "Homebrew packages installed"
    save_state "brew_packages"
}

# Stow dotfiles
stow_dotfiles() {
    if is_step_completed "stow_dotfiles"; then
        print_success "Dotfiles already stowed"
        return
    fi
    
    print_status "📂 Symlinking dotfiles with Stow..."
    cd "$DOTFILES_DIR"
    
    # Create backup of .config directory if it exists
    if [[ -d "$HOME/.config" ]]; then
        create_backup "$HOME/.config" "config_directory"
    fi
    
    # Try stow with adopt to handle conflicts gracefully
    if ! stow --adopt . 2>/dev/null; then
        print_warning "Stow encountered conflicts, trying to resolve..."
        # If adopt fails, try regular stow
        stow . || {
            print_error "Failed to stow dotfiles. Manual conflict resolution required."
        }
    fi
    
    print_success "Dotfiles symlinked"
    save_state "stow_dotfiles"
}

# Setup VS Code and Cursor configurations
setup_vscode() {
    if is_step_completed "vscode"; then
        print_success "VS Code/Cursor already configured"
        return
    fi
    
    print_status "🖥️ Setting up VS Code/Cursor configurations..."
    local vscode_user_dir="$HOME/Library/Application Support/Code/User"
    local cursor_user_dir="$HOME/Library/Application Support/Cursor/User"
    local vscode_config_dir="$DOTFILES_DIR/vscode"
    
    if [[ ! -d "$vscode_config_dir" ]]; then
        print_warning "VS Code config directory not found, skipping..."
        save_state "vscode"
        return
    fi
    
    # Symlink VS Code and Cursor settings
    safe_symlink "$vscode_config_dir/settings.json" "$vscode_user_dir/settings.json" "VS Code"
    safe_symlink "$vscode_config_dir/keybindings.json" "$vscode_user_dir/keybindings.json" "VS Code"
    safe_symlink "$vscode_config_dir/settings.json" "$cursor_user_dir/settings.json" "Cursor"
    safe_symlink "$vscode_config_dir/keybindings.json" "$cursor_user_dir/keybindings.json" "Cursor"
    
    print_success "VS Code/Cursor configurations set up"
    save_state "vscode"
}

# Setup Tmux Plugin Manager
setup_tmux_tpm() {
    if is_step_completed "tmux_tpm"; then
        print_success "Tmux TPM already installed"
        return
    fi
    
    print_status "🖥️ Setting up Tmux Plugin Manager..."
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    
    if [[ ! -d "$tpm_dir" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || {
            print_error "Failed to clone TPM repository"
        }
        print_success "TPM installed"
    else
        print_success "TPM already installed"
    fi
    
    save_state "tmux_tpm"
}

# Setup SketchyBar dependencies
setup_sketchybar() {
    if is_step_completed "sketchybar"; then
        print_success "SketchyBar already configured"
        return
    fi
    
    print_status "🪄 Setting up SketchyBar dependencies..."
    
    # Install SketchyBar App Font
    local font_path="$HOME/Library/Fonts/sketchybar-app-font.ttf"
    if [[ ! -f "$font_path" ]]; then
        print_status "Installing SketchyBar App Font..."
        curl -fsSL https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.40/sketchybar-app-font.ttf -o "$font_path" || {
            print_error "Failed to download SketchyBar App Font"
        }
        print_success "SketchyBar App Font installed"
    else
        print_success "SketchyBar App Font already installed"
    fi
    
    # Download icon_map.sh
    local icon_map_path="$HOME/.config/sketchybar/icon_map.sh"
    if [[ ! -f "$icon_map_path" ]]; then
        print_status "Downloading SketchyBar icon map..."
        mkdir -p "$(dirname "$icon_map_path")"
        curl -fsSL https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.40/icon_map.sh -o "$icon_map_path" || {
            print_error "Failed to download SketchyBar icon map"
        }
        chmod +x "$icon_map_path"
        print_success "SketchyBar icon map downloaded"
    else
        print_success "SketchyBar icon map already exists"
    fi
    
    save_state "sketchybar"
}

# Configure ZSH
configure_zsh() {
    if is_step_completed "zsh_config"; then
        print_success "ZSH already configured"
        return
    fi
    
    print_status "🐚 Configuring ZSH..."
    local zshenv_file="$HOME/.zshenv"
    local zdotdir_line='export ZDOTDIR="$HOME/.config/zshrc"'
    
    # Backup existing .zshenv if it exists
    if [[ -f "$zshenv_file" ]]; then
        create_backup "$zshenv_file" "zshenv"
    fi
    
    if ! grep -q "ZDOTDIR.*/.config/zshrc" "$zshenv_file" 2>/dev/null; then
        echo "$zdotdir_line" >> "$zshenv_file"
        print_success "ZSH configuration added to ~/.zshenv"
    else
        print_success "ZSH already configured"
    fi
    
    save_state "zsh_config"
}

# Install custom fonts
install_fonts() {
    if is_step_completed "fonts"; then
        print_success "Custom fonts already installed"
        return
    fi
    
    print_status "🔤 Installing custom fonts..."
    local fonts_installed=false
    
    # Install fonts from both directories
    for font_dir in "$HOME/.config/fonts/default" "$HOME/.config/fonts/store"; do
        [[ ! -d "$font_dir" ]] && continue
        
        find "$font_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) | while read -r font_file; do
            local font_name=$(basename "$font_file")
            local dest_path="$HOME/Library/Fonts/$font_name"
            
            if [[ -f "$dest_path" ]]; then
                print_warning "Font already exists: $font_name"
            else
                cp "$font_file" "$dest_path" 2>/dev/null && {
                    print_success "Installed font: $font_name"
                    fonts_installed=true
                } || {
                    print_warning "Failed to install font: $font_name"
                }
            fi
        done
    done
    
    if [[ "$fonts_installed" == true ]]; then
        print_success "Custom fonts installed"
    else
        print_success "No additional fonts to install"
    fi
    
    save_state "fonts"
}


# Verify installation
verify_installation() {
    print_status "🔍 Verifying installation..."
    
    local verification_failed=false
    
    # Check critical commands
    local critical_commands=("brew" "stow" "git" "zsh")
    for cmd in "${critical_commands[@]}"; do
        if command_exists "$cmd"; then
            print_success "$cmd is available"
        else
            print_warning "$cmd is not available"
            verification_failed=true
        fi
    done
    
    # Check critical paths
    local critical_paths=("$HOME/.config" "$DOTFILES_DIR")
    for path in "${critical_paths[@]}"; do
        if [[ -d "$path" ]]; then
            print_success "$path exists"
        else
            print_warning "$path does not exist"
            verification_failed=true
        fi
    done
    
    # Check symlinks
    if [[ -L "$HOME/.config/zshrc/.zshrc" ]]; then
        print_success "ZSH configuration symlinked"
    else
        print_warning "ZSH configuration may not be properly linked"
    fi
    
    if [[ "$verification_failed" == true ]]; then
        print_warning "Some verification checks failed. Check the log: $LOG_FILE"
    else
        print_success "Installation verification passed"
    fi
}

# Cleanup and finish
finish_installation() {
    local end_time
    end_time=$(date)
    
    echo "Completed: $end_time" >> "$LOG_FILE"
    
    # Clean up state file on successful completion
    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        print_verbose "Cleaned up state file"
    fi
    
    echo
    print_success "🎉 Dotfiles setup complete!"
    echo
    echo -e "${BLUE}Summary:${NC}"
    echo "  • Installation completed at: $end_time"
    echo "  • Dotfiles location: $DOTFILES_DIR"
    if [[ "$SKIP_BACKUP" != "true" ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo "  • Backup location: $BACKUP_DIR"
    fi
    echo "  • Log file: $LOG_FILE"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "  • Restart your terminal to load new configurations"
    echo "  • For Tmux: Open tmux and press Ctrl+Space + I to install plugins"
    echo "  • For VS Code: Restart VS Code/Cursor to load new settings"
    echo
}

# Main installation function
main() {
    # Initialize installation steps tracking
    declare -A INSTALL_STEPS=(
        ["homebrew"]="false"
        ["clone_repo"]="false"
        ["brew_packages"]="false"
        ["stow_dotfiles"]="false"
        ["vscode"]="false"
        ["tmux_tpm"]="false"
        ["sketchybar"]="false"
        ["zsh_config"]="false"
        ["fonts"]="false"
    )
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize logging
    init_logging "$@"
    
    echo
    print_status "🚀 Dotfiles Installation Script v${SCRIPT_VERSION}"
    print_status "Repository: $DOTFILES_REPO"
    print_status "Directory: $DOTFILES_DIR"
    echo
    
    # Check system requirements
    check_requirements
    
    # Load previous state if exists
    load_state
    
    # Detect system
    detect_system
    
    # Run installation steps
    install_homebrew
    clone_dotfiles
    
    if [[ "$INSTALL_PACKAGES" == true ]]; then
        install_brew_packages
    else
        print_status "Skipping package installation (--no-packages flag)"
    fi
    
    stow_dotfiles
    setup_vscode
    setup_tmux_tpm
    setup_sketchybar
    configure_zsh
    install_fonts
    
    # Verify installation
    verify_installation
    
    # Finish up
    finish_installation
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi