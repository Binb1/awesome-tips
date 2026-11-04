#!/bin/bash
# Install everything in this repo onto this Mac. Idempotent: safe to re-run
# after a `git pull`. Pieces whose app/binary is missing are skipped and
# listed at the end. See SETUP.md for the agent-facing walkthrough.
#
#   ./setup.sh          install configs (no package installs)
#   ./setup.sh --brew   also run `brew bundle` on mac-setup/Brewfile first
set -u
R=$(cd "$(dirname "$0")" && pwd)
MANUAL=(); SKIPPED=(); DONE=()
note() { DONE+=("$1"); echo "  ✓ $1"; }
skip() { SKIPPED+=("$1"); echo "  - skipped: $1"; }
manual() { MANUAL+=("$1"); }
same() { [ -f "$2" ] && cmp -s "$1" "$2"; }
install_file() { # src dst label
  mkdir -p "$(dirname "$2")"
  if same "$1" "$2"; then echo "  = $3 (unchanged)"; else cp "$1" "$2"; note "$3"; fi
}

echo "== Homebrew"
if [ "${1:-}" = "--brew" ]; then
  if command -v brew >/dev/null; then brew bundle --file="$R/mac-setup/Brewfile" && note "brew bundle"; else skip "brew not installed"; fi
else echo "  (pass --brew to run brew bundle)"; fi

echo "== Ghostty"
if [ -d /Applications/Ghostty.app ]; then
  install_file "$R/ghostty/config" ~/.config/ghostty/config "ghostty config"
  for t in "$R"/ghostty/themes/*; do install_file "$t" ~/.config/ghostty/themes/"$(basename "$t")" "ghostty theme $(basename "$t")"; done
  for i in "$R"/ghostty/icons/*.icns; do [ -e "$i" ] && install_file "$i" ~/.config/ghostty/icons/"$(basename "$i")" "ghostty icon $(basename "$i")"; done
  [ -e ~/.config/ghostty/icons/current.icns ] || ln -s ~/.config/ghostty/icons/ayu-light.icns ~/.config/ghostty/icons/current.icns 2>/dev/null
  ov=~/Library/Application\ Support/com.mitchellh.ghostty/auto/theme.ghostty
  [ -e "$ov" ] && { rm -f "$ov"; note "removed in-app theme override that silently wins over config"; }
  /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config >/dev/null 2>&1 && note "ghostty config validates" || manual "ghostty +validate-config reported errors: run it and fix"
  pgrep -x ghostty >/dev/null && manual "Ghostty is running: press Cmd+Shift+, in it to reload the config"
else skip "Ghostty.app not installed"; fi

echo "== Herdr"
if command -v herdr >/dev/null; then
  live=~/.config/herdr/config.toml; mkdir -p ~/.config/herdr
  block=""
  if [ -f "$live" ] && grep -q '^# >>> herdr-ghostty-sidebar' "$live"; then
    block=$(awk '/^# >>> herdr-ghostty-sidebar/{p=1} p{print} /^# <<< herdr-ghostty-sidebar/{p=0}' "$live")
  fi
  tmp=$(mktemp); cp "$R/herdr/config.toml" "$tmp"
  [ -n "$block" ] && printf '\n%s\n' "$block" >> "$tmp"
  if same "$tmp" "$live"; then echo "  = herdr config (unchanged)"; else cp "$tmp" "$live"; note "herdr config (sidebar block preserved: $([ -n "$block" ] && echo yes || echo none))"; fi
  rm -f "$tmp"
  herdr server reload-config >/dev/null 2>&1 && note "herdr server reloaded" || true
  if ! herdr plugin list 2>/dev/null | grep -q binb1.ghostty-sidebar; then manual "inside a Herdr pane: herdr plugin install Binb1/herdr-ghostty-sidebar --ref v0.1.2 --yes && herdr plugin action invoke setup --plugin binb1.ghostty-sidebar (then quit/reopen Ghostty for the logo font)"; fi
  if ! herdr plugin list 2>/dev/null | grep -q binb1.palette; then manual "herdr plugin install Binb1/herdr-palette --ref main --yes"; fi
  [ -f ~/.claude/hooks/herdr-agent-state.sh ] || { herdr integration install claude >/dev/null 2>&1 && note "herdr Claude Code integration" || manual "herdr integration install claude"; }
else skip "herdr not installed (brew install herdr)"; fi

echo "== Zed"
if [ -d /Applications/Zed.app ] || [ -d ~/.config/zed ]; then
  for t in "$R"/zed/themes/*.json; do install_file "$t" ~/.config/zed/themes/"$(basename "$t")" "zed theme $(basename "$t")"; done
  s=~/.config/zed/settings.json
  if [ -f "$s" ]; then
    if grep -q '"light": "Latte Custom"' "$s" && grep -q '"dark": "Mocha Custom"' "$s"; then echo "  = zed settings already use the themes"
    elif grep -q '"light":' "$s" && grep -q '"dark":' "$s"; then
      sed -i '' -E 's/"light": *"[^"]*"/"light": "Latte Custom"/; s/"dark": *"[^"]*"/"dark": "Mocha Custom"/' "$s"; note "zed settings: theme light/dark set"
    else manual "zed settings.json: add  \"theme\": { \"mode\": \"system\", \"light\": \"Latte Custom\", \"dark\": \"Mocha Custom\" }"; fi
  else
    mkdir -p ~/.config/zed; printf '{\n  "theme": { "mode": "system", "light": "Latte Custom", "dark": "Mocha Custom" }\n}\n' > "$s"; note "zed settings.json created"
  fi
else skip "Zed not installed"; fi

echo "== Rex"
if command -v rex >/dev/null; then
  "$R/rex/apply.sh" >/dev/null && note "rex init.lua, themes and preferences" && manual "quit and reopen Rex so it reads the themes (sessions survive, they live in the server)"
else skip "rex CLI not installed"; fi

echo "== Zsh"
line="source \"$R/zsh/awesome-tips.zsh\""
if grep -qF "zsh/awesome-tips.zsh" ~/.zshrc 2>/dev/null; then echo "  = ~/.zshrc already sources zsh/awesome-tips.zsh"
else printf '\n# awesome-tips shared shell config (cursor hook, herdr helpers)\n%s\n' "$line" >> ~/.zshrc; note "~/.zshrc sources zsh/awesome-tips.zsh"; fi
if grep -q -E '^_orange_cursor\(\)|^_theme_cursor\(\)|^h\(\) \{' ~/.zshrc 2>/dev/null; then manual "~/.zshrc still defines _theme_cursor/h inline; remove them, zsh/awesome-tips.zsh now provides them"; fi
[ -d ~/.oh-my-zsh ] || manual "install oh-my-zsh + plugins listed in zsh/.zshrc (git z zsh-autosuggestions zsh-syntax-highlighting)"

echo "== Vim"
install_file "$R/vim/vimrc" ~/.vimrc "vimrc"

echo "== Claude Code"
mkdir -p ~/.claude/agents ~/.claude/commands
for f in "$R"/claude-code/agents/*.md; do install_file "$f" ~/.claude/agents/"$(basename "$f")" "claude agent $(basename "$f")"; done
for f in "$R"/claude-code/commands/*.md; do install_file "$f" ~/.claude/commands/"$(basename "$f")" "claude command $(basename "$f")"; done
cs=~/.claude/settings.json; want="bash $R/claude-code/statusline/statusline.sh"
if command -v jq >/dev/null && [ -f "$cs" ]; then
  if [ "$(jq -r '.statusLine.command // ""' "$cs")" = "$want" ]; then echo "  = statusline already configured"
  else tmp=$(mktemp); jq --arg c "$want" '.statusLine = {type:"command", command:$c}' "$cs" > "$tmp" && mv "$tmp" "$cs" && note "claude statusline -> repo script"; fi
elif [ -f "$cs" ]; then manual "set statusLine.command in ~/.claude/settings.json to: $want (jq missing)"
else mkdir -p ~/.claude; printf '{\n  "statusLine": { "type": "command", "command": "%s" }\n}\n' "$want" > "$cs"; note "claude settings.json created with statusline"; fi

echo "== SwiftBar"
pd=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null | sed "s|^~|$HOME|")
if [ -n "$pd" ] && [ -d "$pd" ]; then
  for f in "$R"/herdr/swiftbar/*.sh; do install_file "$f" "$pd/$(basename "$f")" "swiftbar $(basename "$f")"; chmod +x "$pd/$(basename "$f")"; done
else skip "SwiftBar plugin folder not found (brew install --cask swiftbar, launch it once)"; fi

echo; echo "== Summary: ${#DONE[@]} changed, ${#SKIPPED[@]} skipped, ${#MANUAL[@]} manual"
for m in "${MANUAL[@]}"; do echo "  MANUAL: $m"; done
