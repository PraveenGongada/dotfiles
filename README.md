# My dotfiles

This repository contains the dotfiles for my system

## Requirements

Ensure you have the following installed on your system

### Git

```bash
brew install git
```

### Stow

```bash
brew install stow
```

## Installation

First, check out the dotfiles repo using git

```bash
cd ~ && git clone git@github.com:PraveenGongada/dotfiles.git
```

```bash
cd dotfiles
```

## Post Installation

Run the following commands to setup the environment

### Adding symlinks

```bash
stow .
```

### Setting up zshrc

Create ~/.zshenv and set ZDOTDIR to point to ~/.config/zshrc

```bash
echo 'export ZDOTDIR="$HOME/.config/zshrc"' >> ~/.zshenv
```

### Installation Homebrew Packages:

```bash
# Backing up data
{ brew leaves -r; brew list --cask; } > ~/.config/homebrew/leaves.txt
```

```bash
# Installing from backup
xargs brew install < ~/.config/homebrew/leaves.txt
```

### Insalling Custom Fonts

⚠️ : This will overwrite any fonts with same name in the system

Install the default fonts to Font Library

```bash
find ~/.config/fonts/default/ -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} ~/Library/Fonts/ \;
```

Install the store fonts to Font Library

```bash
find ~/.config/fonts/store/ -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} ~/Library/Fonts/ \;
```

Install specific font to Font Library

```bash
find ~/.config/fonts/$PATH_TO_FONT/ -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} ~/Library/Fonts/ \;
```
