# Zen

## Setup

Open Zen once so it creates a profile, then link the files into it:

```bash
zen="$HOME/Library/Application Support/zen"
profile="$zen/$(awk -F= '/^\[Install/ { s = 1; next } /^\[/ { s = 0 } s && $1 == "Default" { print $2; exit }' "$zen/profiles.ini")"
mkdir -p "$profile/chrome"
ln -sf ~/dotfiles/zen/user.js "$profile/user.js"
ln -sf ~/dotfiles/zen/customKeys.json "$profile/customKeys.json"
ln -sf ~/dotfiles/zen/chrome/userChrome.css "$profile/chrome/userChrome.css"
```

Install the extension, click Add when Zen asks, then restart Zen:

```bash
open -a Zen ~/dotfiles/zen/extensions/tab-step.xpi
```
