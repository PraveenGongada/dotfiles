# SketchyBar Setup

## Install sketchybar

Run the following command

```
brew install felixkratz/formulae/sketchybar
```

## Install command line JSON processor (jq)

Run the following command to install jq

```
brew install jq
```

## Install SF Pro Font & SF Symbols

Install the SF Pro font which is the font for MacOs

```
brew install font-sf-pro
```

Install SF Symbols which is an icons/symbols library made for SF Pro

```
brew install --cask sf-symbols
```

## Install and setup sketchybar-app-font

Run the following command to install the sketchybar-app-font

```
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
```

Run the following command to add icon_map.sh file to ~/.config/sketchybar/plugins

```
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/icon_map.sh -o ~/.config/sketchybar/plugins/icon_map.sh
```

Open icon_map.sh file and add the following to the end of the file

```
__icon_map "$1"

echo "$icon_result"

```
