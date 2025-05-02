# 🪄 SketchyBar

<div align="center">

<br/>
<a href="https://github.com/FelixKratz/SketchyBar"><img src="https://img.shields.io/badge/SketchyBar-macOS-C13584?style=for-the-badge&logoColor=white" alt="macOS Status Bar"/></a>

_A customizable replacement for the macOS status bar_

</div>

## 📸 Preview

![Tmux](../docs/images/sketchybar.png)

## 🚀 Installation

**Install SketchyBar**

```bash
brew install felixkratz/formulae/sketchybar
```

**Install jq**

```bash
brew install jq
```

## 🔤 Font Setup

**Install SF Pro Font**

```bash
brew install font-sf-pro
```

**Install SF Symbols**

```bash
brew install --cask sf-symbols
```

**Install SketchyBar App Font**

```bash
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.32/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
```

**Add icon_map.sh file**

```bash
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.32/icon_map.sh -o $HOME/.config/sketchybar/icon_map.sh
```

## ⚙️ Configuration

The configuration files are organized as follows:

- `sketchybarrc` - Main configuration file
- `colors.sh` - Color definitions
- `items/` - Individual component configurations
- `plugins/` - Interactive plugin scripts

## 🔗 Useful Links

- [Official SketchyBar Repository](https://github.com/FelixKratz/SketchyBar)
- [SketchyBar Wiki](https://github.com/FelixKratz/SketchyBar/wiki)
- [SketchyBar Examples](https://github.com/FelixKratz/SketchyBar/discussions/47)
