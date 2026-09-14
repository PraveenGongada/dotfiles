#!/usr/bin/env bash
# Dotfiles installer for macOS. Idempotent; never overwrites without --force.
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/PraveenGongada/dotfiles/main/setup.sh)"

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/PraveenGongada/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)}"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"

SKETCHYBAR_FONT_VERSION="v2.0.40"
SKETCHYBAR_FONT_URL="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/$SKETCHYBAR_FONT_VERSION"

MAC_STEPS="xcode homebrew repo packages stow links zsh tmux sketchybar fonts"
SERVER_STEPS="apt repo tools stow links zsh tmux"
ALL_STEPS=""

APT_PACKAGES="zsh git curl unzip xz-utils tmux ripgrep fd-find zoxide stow build-essential file"
SERVER_STOW_IGNORE='^(sketchybar|aerospace|homebrew|wallpapers|fonts|ghostty|kitty|wezterm|zed)(/|$)'

PROFILE=mac
FORCE=false
DRY_RUN=false
VERBOSE=false
LIST=false
ONLY=""
SKIP=""
FAILED=""
CONFLICTS=""

# --------------------------------------------------------------------------- output

if [[ -t 1 ]]; then
  C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m' C_BLUE=$'\033[0;34m' C_YELLOW=$'\033[1;33m' C_DIM=$'\033[2m' C_NC=$'\033[0m'
else
  C_RED="" C_GREEN="" C_BLUE="" C_YELLOW="" C_DIM="" C_NC=""
fi

info()    { printf '%s==>%s %s\n' "$C_BLUE" "$C_NC" "$*"; }
ok()      { printf '%s  ✓%s %s\n' "$C_GREEN" "$C_NC" "$*"; }
warn()    { printf '%s  !%s %s\n' "$C_YELLOW" "$C_NC" "$*" >&2; }
err()     { printf '%s  ✗%s %s\n' "$C_RED" "$C_NC" "$*" >&2; }
die()     { err "$@"; exit 1; }
verbose() { [[ "$VERBOSE" == true ]] && printf '%s    %s%s\n' "$C_DIM" "$*" "$C_NC" || true; }

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '%s    [dry-run]%s %s\n' "$C_DIM" "$C_NC" "$*"
    return 0
  fi
  verbose "$ $*"
  "$@"
}

usage() {
  cat <<EOF
Usage: setup.sh [options]

Options:
  --force          Replace existing files that conflict with the dotfiles
                   (they are moved to a backup dir first)
  --server         Linux box over SSH: shell, Neovim, tmux and the CLI tools
  --dry-run        Show what would change without changing anything
  --only STEPS     Run only these steps (comma separated)
  --skip STEPS     Skip these steps (comma separated)
  --list           List the available steps
  -v, --verbose    Show every command that is run
  -h, --help       Show this help

Steps:          $MAC_STEPS
Steps (server): $SERVER_STEPS

Environment:
  DOTFILES_REPO    Repository to clone      (default: $DOTFILES_REPO)
  DOTFILES_DIR     Where to clone it        (default: ~/dotfiles, or the
                   checkout setup.sh is run from)
  BACKUP_DIR       Where --force puts replaced files
                   (default: ~/.dotfiles_backup_<timestamp>)
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force) FORCE=true ;;
      --server) PROFILE=server ;;
      --dry-run) DRY_RUN=true ;;
      --only) [[ $# -ge 2 ]] || die "--only needs a value"; ONLY="${2//,/ }"; shift ;;
      --skip) [[ $# -ge 2 ]] || die "--skip needs a value"; SKIP="${2//,/ }"; shift ;;
      --list) LIST=true ;;
      -v|--verbose) VERBOSE=true ;;
      -h|--help) usage; exit 0 ;;
      *) err "Unknown option: $1"; usage >&2; exit 1 ;;
    esac
    shift
  done
}

# --------------------------------------------------------------------------- helpers

has() { command -v "$1" >/dev/null 2>&1; }

in_list() {
  local needle="$1" item
  shift
  for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
  return 1
}

should_run() {
  local step="$1"
  # shellcheck disable=SC2086
  if [[ -n "$ONLY" ]] && ! in_list "$step" $ONLY; then return 1; fi
  # shellcheck disable=SC2086
  if [[ -n "$SKIP" ]] && in_list "$step" $SKIP; then return 1; fi
  return 0
}

backup() {
  local target="$1" rel dest
  case "$target" in
    "$HOME"/*) rel="${target#"$HOME"/}" ;;
    *) rel="${target#/}" ;;
  esac
  dest="$BACKUP_DIR/$rel"
  run mkdir -p "$(dirname "$dest")"
  run mv "$target" "$dest"
  ok "Backed up $target -> $dest"
}

# Returns 0 when the caller may replace the file
resolve_conflict() {
  local target="$1"
  if [[ "$FORCE" == true ]]; then
    backup "$target"
    return 0
  fi
  warn "Exists, not managed by dotfiles, left untouched: $target"
  CONFLICTS="$CONFLICTS
$target"
  return 1
}

link_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      verbose "Already linked: $dst"
      return 0
    fi
    resolve_conflict "$dst" || return 0
  elif [[ -e "$dst" ]]; then
    resolve_conflict "$dst" || return 0
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  ok "Linked $dst -> $src"
}

ensure_line() {
  local line="$1" file="$2"
  if [[ -f "$file" ]] && grep -qxF "$line" "$file"; then
    verbose "Already present in $file: $line"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    run "append to $file:" "$line"
  else
    printf '%s\n' "$line" >> "$file"
  fi
  ok "Added to $file: $line"
}

fetch_file() {
  local url="$1" dst="$2"
  if [[ -f "$dst" ]]; then
    verbose "Already present: $dst"
    return 0
  fi
  run mkdir -p "$(dirname "$dst")"
  if [[ "$DRY_RUN" == true ]]; then
    run curl -fsSL "$url" -o "$dst"
  else
    curl -fsSL "$url" -o "$dst.tmp" && mv "$dst.tmp" "$dst"
  fi
  ok "Downloaded $dst"
}

# --------------------------------------------------------------------------- steps (shared)

step_repo() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    ok "Repository present at $DOTFILES_DIR"
    return 0
  fi
  if [[ -e "$DOTFILES_DIR" ]]; then
    die "$DOTFILES_DIR exists but is not a git repository; move it or set DOTFILES_DIR"
  fi
  info "Cloning $DOTFILES_REPO -> $DOTFILES_DIR"
  run git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

# Conflicting files are backed up (--force) or their top-level dir is skipped
step_stow() {
  if [[ ! -f "$DOTFILES_DIR/.stowrc" ]]; then
    [[ "$DRY_RUN" == true ]] && return 0
    die "Not a dotfiles checkout: $DOTFILES_DIR"
  fi
  if ! has stow; then
    has brew || { warn "stow not available, skipping"; return 1; }
    run brew install stow
  fi
  run mkdir -p "$CONFIG_DIR"

  local out line target top conflicts="" skipped="" ignore=()
  [[ "$PROFILE" == server ]] && ignore+=(--ignore="$SERVER_STOW_IGNORE")
  out="$(cd "$DOTFILES_DIR" && stow --no --restow "${ignore[@]+"${ignore[@]}"}" . 2>&1)" || true
  while IFS= read -r line; do
    case "$line" in
      *"existing target is "*": "*) target="${line##*: }" ;;
      *"over existing target "*" since "*) target="${line#*over existing target }"; target="${target%% since*}" ;;
      *) continue ;;
    esac
    conflicts="$conflicts
$target"
  done <<< "$out"

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    resolve_conflict "$CONFIG_DIR/$target" && continue
    top="${target%%/*}"
    in_list "$top" $skipped && continue
    skipped="$skipped $top"
    ignore+=(--ignore="^$top")
  done <<< "$conflicts"

  if [[ "$DRY_RUN" == true ]]; then
    run stow --restow "${ignore[@]+"${ignore[@]}"}" .
  else
    (cd "$DOTFILES_DIR" && stow --restow "${ignore[@]+"${ignore[@]}"}" .)
  fi
  if [[ -n "$skipped" ]]; then
    warn "Stowed everything except:$skipped (re-run with --force to replace the files above)"
    return 1
  fi
  ok "Stowed dotfiles into $CONFIG_DIR"
}

# Files outside ~/.config
step_links() {
  local app
  if [[ "$PROFILE" == mac ]]; then
    for app in Code Cursor; do
      link_file "$DOTFILES_DIR/vscode/settings.json"    "$HOME/Library/Application Support/$app/User/settings.json"
      link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/$app/User/keybindings.json"
    done
  fi
  link_file "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
}

step_zsh() {
  ensure_line 'export ZDOTDIR="$HOME/.config/zshrc"' "$HOME/.zshenv"
  ok "ZDOTDIR points at $CONFIG_DIR/zshrc"
  [[ "$PROFILE" == server ]] || return 0
  local zsh
  zsh="$(command -v zsh)" || { warn "zsh not installed"; return 1; }
  if [[ "$(getent passwd "$(id -un)" | cut -d: -f7)" != "$zsh" ]]; then
    info "Making zsh the login shell..."
    run $SUDO chsh -s "$zsh" "$(id -un)" || { warn "chsh failed; run it yourself: chsh -s $zsh"; return 1; }
  fi
  ok "Login shell is zsh"
}

step_tmux() {
  local tpm="$CONFIG_DIR/tmux/plugins/tpm"
  if [[ ! -d "$tpm" ]]; then
    info "Installing tmux plugin manager..."
    run git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm"
  fi
  if [[ -x "$tpm/bin/install_plugins" ]] && has tmux; then
    run "$tpm/bin/install_plugins" >/dev/null
  fi
  ok "tmux plugins installed"
}

# --------------------------------------------------------------------------- steps (macOS)

step_xcode() {
  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode Command Line Tools present"
    return 0
  fi
  info "Installing Xcode Command Line Tools (accept the dialog)..."
  run xcode-select --install
  [[ "$DRY_RUN" == true ]] && return 0
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
  ok "Xcode Command Line Tools installed"
}

step_homebrew() {
  if ! has brew && [[ -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
  fi
  if ! has brew; then
    info "Installing Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ "$DRY_RUN" == true ]] && { warn "Homebrew not installed; later steps assume it"; return 0; }
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
    has brew || die "Homebrew installation failed"
  fi
  ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"
}

step_packages() {
  local brewfile="$DOTFILES_DIR/homebrew/Brewfile"
  if [[ ! -f "$brewfile" ]]; then
    [[ "$DRY_RUN" == true ]] && return 0
    die "Brewfile not found: $brewfile"
  fi
  has brew || { warn "brew not available, skipping packages"; return 1; }
  if brew bundle check --file="$brewfile" --no-upgrade >/dev/null 2>&1; then
    ok "All Brewfile packages installed"
    return 0
  fi
  info "Installing missing packages from Brewfile (this can take a while)..."
  run brew bundle install --file="$brewfile" --no-upgrade
}

step_sketchybar() {
  fetch_file "$SKETCHYBAR_FONT_URL/sketchybar-app-font.ttf" "$HOME/Library/Fonts/sketchybar-app-font.ttf"
  fetch_file "$SKETCHYBAR_FONT_URL/icon_map.sh" "$CONFIG_DIR/sketchybar/icon_map.sh"
  [[ "$DRY_RUN" == true ]] || chmod +x "$CONFIG_DIR/sketchybar/icon_map.sh"
  ok "SketchyBar font and icon map present"
}

step_fonts() {
  local dir font dst n=0
  for dir in "$DOTFILES_DIR/fonts/default" "$DOTFILES_DIR/fonts/store"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r font; do
      dst="$HOME/Library/Fonts/$(basename "$font")"
      [[ -f "$dst" ]] && continue
      run cp "$font" "$dst"
      n=$((n + 1))
    done < <(find "$dir" -type f \( -name '*.ttf' -o -name '*.otf' \))
  done
  if [[ "$DRY_RUN" == true ]]; then ok "Fonts: $n to install"; else ok "Fonts: $n installed"; fi
}

# --------------------------------------------------------------------------- steps (server)

installed() {
  local n
  for n in "$@"; do [[ -x "$BIN_DIR/$n" ]] || return 1; done
}

gh_latest() {
  curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/tag/##'
}

install_bins() {
  local url="$1" tmp src name
  shift
  if [[ "$DRY_RUN" == true ]]; then run "install $* from $url"; return 0; fi
  tmp="$(mktemp -d)"
  case "$url" in
    *.tar.gz|*.tgz|*.tar.xz) curl -fsSL "$url" -o "$tmp/archive" && tar -xf "$tmp/archive" -C "$tmp" ;;
    *.zip) curl -fsSL "$url" -o "$tmp/archive" && unzip -qo "$tmp/archive" -d "$tmp" ;;
    *) curl -fsSL "$url" -o "$tmp/$1" ;;
  esac || { rm -rf "$tmp"; err "Download failed: $url"; return 1; }
  for name in "$@"; do
    src="$(find "$tmp" -type f -name "$name" | head -1)"
    [[ -n "$src" ]] || { rm -rf "$tmp"; err "$name not found in $url"; return 1; }
    install -m 755 "$src" "$BIN_DIR/$name"
  done
  rm -rf "$tmp"
}

install_release() {
  local repo="$1" asset="$2" tag
  shift 2
  if installed "$@"; then ok "$1 present"; return 0; fi
  tag="$(gh_latest "$repo")" || { err "Could not resolve latest release of $repo"; return 1; }
  asset="${asset//%t/$tag}"
  asset="${asset//%v/${tag#v}}"
  install_bins "https://github.com/$repo/releases/download/$tag/$asset" "$@" || return 1
  ok "$1 $tag"
}

install_tree() {
  local name="$1" url="$2" dest="$OPT_DIR/$1" tmp b
  shift 2
  if [[ -x "$dest/bin/$1" ]]; then
    ok "$name present"
  elif [[ "$DRY_RUN" == true ]]; then
    run "install $name into $dest from $url"
  else
    tmp="$(mktemp)"
    curl -fsSL "$url" -o "$tmp" || { rm -f "$tmp"; err "Download failed: $url"; return 1; }
    rm -rf "$dest" && mkdir -p "$dest"
    tar -xf "$tmp" -C "$dest" --strip-components=1 || { rm -f "$tmp"; err "Could not unpack $url"; return 1; }
    rm -f "$tmp"
    ok "$name installed in $dest"
  fi
  for b in "$@"; do link_file "$dest/bin/$b" "$BIN_DIR/$b"; done
}

step_apt() {
  has apt-get || { warn "apt-get not found; install these yourself: $APT_PACKAGES eza"; return 1; }
  local p missing=()
  for p in $APT_PACKAGES; do dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p"); done
  if [[ ${#missing[@]} -gt 0 ]] || ! has eza; then
    run $SUDO apt-get update -qq || return 1
    if ! has eza && apt-cache show eza >/dev/null 2>&1; then missing+=(eza); fi
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    info "Installing: ${missing[*]}"
    run $SUDO apt-get install -y -qq "${missing[@]}" || return 1
  fi
  ok "apt packages present"
  if ! has fd && has fdfind; then link_file "$(command -v fdfind)" "$BIN_DIR/fd"; fi
}

step_tools() {
  local arch goarch ver rc=0
  case "$(uname -m)" in
    x86_64) arch=x86_64 goarch=amd64 ;;
    aarch64) arch=aarch64 goarch=arm64 ;;
    *) err "Unsupported architecture: $(uname -m)"; return 1 ;;
  esac
  run mkdir -p "$BIN_DIR" "$OPT_DIR"

  install_tree nvim "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch/aarch64/arm64}.tar.gz" nvim || rc=1
  install_release junegunn/fzf "fzf-%v-linux_${goarch}.tar.gz" fzf || rc=1
  install_release jesseduffield/lazygit "lazygit_%v_Linux_${arch/aarch64/arm64}.tar.gz" lazygit || rc=1
  install_release sxyazi/yazi "yazi-${arch}-unknown-linux-gnu.zip" yazi ya || rc=1
  install_release JanDeDobbeleer/oh-my-posh "posh-linux-${goarch}" oh-my-posh || rc=1
  has eza || install_release eza-community/eza "eza_${arch}-unknown-linux-gnu.tar.gz" eza || rc=1

  if ver="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)"; then
    install_tree go "https://go.dev/dl/${ver}.linux-${goarch}.tar.gz" go gofmt || rc=1
  else
    err "Could not resolve latest Go version"; rc=1
  fi
  if ver="$(curl -fsSL https://nodejs.org/dist/index.json)" && ver="$(grep -m1 '"lts":"[A-Z]' <<<"$ver" | sed 's/.*"version":"\(v[^"]*\)".*/\1/')" && [[ -n "$ver" ]]; then
    install_tree node "https://nodejs.org/dist/$ver/node-$ver-linux-${goarch/amd64/x64}.tar.xz" node npm npx || rc=1
  else
    err "Could not resolve latest Node LTS version"; rc=1
  fi
  return $rc
}

# --------------------------------------------------------------------------- main

main() {
  parse_args "$@"

  [[ "$PROFILE" == server ]] && ALL_STEPS="$SERVER_STEPS" || ALL_STEPS="$MAC_STEPS"
  if [[ "$LIST" == true ]]; then echo "$ALL_STEPS" | tr ' ' '\n'; exit 0; fi
  case "$PROFILE:$(uname -s)" in
    mac:Darwin|server:Linux) ;;
    mac:*) die "This installer supports macOS; on a Linux box run it with --server" ;;
    server:*) die "--server is for Linux" ;;
  esac

  if [[ "$(uname -m)" == arm64 ]]; then HOMEBREW_PREFIX=/opt/homebrew; else HOMEBREW_PREFIX=/usr/local; fi
  SUDO=""; [[ $EUID -eq 0 ]] || SUDO=sudo
  export PATH="$BIN_DIR:$PATH"

  # curl | bash: give prompts a terminal
  if [[ ! -t 0 ]] && ( : </dev/tty ) 2>/dev/null; then exec </dev/tty; fi

  if [[ -z "$DOTFILES_DIR" ]]; then
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]:-/nonexistent}")" 2>/dev/null && pwd)" || here=""
    if [[ -n "$here" && -f "$here/.stowrc" ]]; then
      DOTFILES_DIR="$here"
    else
      DOTFILES_DIR="$HOME/dotfiles"
    fi
  fi

  echo
  info "Dotfiles installer"
  echo "    repo:    $DOTFILES_REPO"
  echo "    dir:     $DOTFILES_DIR"
  [[ "$PROFILE" == server ]] && echo "    profile: server (terminal-only)"
  [[ "$FORCE" == true ]]   && echo "    backups: $BACKUP_DIR"
  [[ "$DRY_RUN" == true ]] && echo "    mode:    dry run (nothing will change)"
  echo

  local step
  for step in $ALL_STEPS; do
    should_run "$step" || { verbose "Skipping $step"; continue; }
    info "[$step]"
    if ! "step_$step"; then
      FAILED="$FAILED $step"
      err "Step '$step' failed, continuing"
    fi
  done

  echo
  if [[ -n "$CONFLICTS" ]]; then
    warn "Left untouched because they already exist (re-run with --force to replace; originals go to $BACKUP_DIR):"
    while IFS= read -r line; do [[ -n "$line" ]] && echo "      $line"; done <<< "$CONFLICTS"
    echo
  fi
  if [[ -n "$FAILED" ]]; then
    err "Finished with failures:$FAILED"
    echo "    Fix the cause and re-run; steps that are already done are skipped automatically."
    exit 1
  fi
  ok "Done. Open a new terminal to load the shell config."
}

main "$@"
