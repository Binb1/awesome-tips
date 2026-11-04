#!/bin/sh
# Install the Rex config and preferences from this folder.
#   init.lua     -> ~/.config/rex/init.lua (keybindings), reloaded live
#   themes.json  -> Rex custom themes (latte-custom light / mocha-custom dark)
#   defaults     -> theme selection + the terminal rendering switches
# Theme/preference changes are read when the Rex app launches: quit and reopen
# it afterwards. Sessions live in the Rex server, not the app, so they survive.
set -e
D=$(cd "$(dirname "$0")" && pwd)
APP=com.superlogical.rex

mkdir -p ~/.config/rex
cp "$D/init.lua" ~/.config/rex/init.lua

hex=$(python3 - "$D/themes.json" <<'PY'
import json, sys
themes = json.load(open(sys.argv[1]))
print(json.dumps(themes, separators=(",", ":")).encode().hex())
PY
)
defaults write "$APP" Workspace.customThemes -data "$hex"
light=$(python3 -c 'import json,sys;print(next(t["id"] for t in json.load(open(sys.argv[1])) if t["appearance"]=="light"))' "$D/themes.json")
dark=$(python3 -c 'import json,sys;print(next(t["id"] for t in json.load(open(sys.argv[1])) if t["appearance"]=="dark"))' "$D/themes.json")
defaults write "$APP" Workspace.lightThemeID -string "$light"
defaults write "$APP" Workspace.darkThemeID -string "$dark"
defaults write "$APP" Workspace.interfaceStyle -string useTheme
# Without these the theme's cursor/selection colours are ignored (cursor falls back to white).
defaults write "$APP" Workspace.lightUsesExtendedThemePalette -bool true
defaults write "$APP" Workspace.darkUsesExtendedThemePalette -bool true
# Rendering: wide-gamut like Ghostty (window-colorspace = display-p3), and no
# automatic recolouring of text or the cursor.
defaults write "$APP" Workspace.terminalUsesDisplayP3 -bool true
defaults write "$APP" Workspace.terminalImproveTextContrast -bool false
defaults write "$APP" Workspace.terminalUseThemePalette -bool false
defaults write "$APP" Workspace.usesPaneGlass -bool false
defaults write "$APP" Workspace.inactivePaneFadeMode -string none

rex config reload >/dev/null 2>&1 || true
echo "Rex: init.lua installed and reloaded; themes + preferences written."
echo "Quit and reopen Rex to apply the theme changes (sessions survive)."
