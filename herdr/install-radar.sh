#!/bin/zsh
# Install the vendored herdr-radar sidebar (herdr/herdr-radar) on this Mac.
# Idempotent: re-run after pulling changes to the plugin or radar-config.toml.
#
#   herdr/install-radar.sh
#
# Does: install the plugin from GitHub (Binb1/awesome-tips/herdr/herdr-radar on
# main — Herdr keeps its own copy, so switching branches here can't break it;
# push plugin changes before re-running), install our settings, install the
# two fonts (radar's merged JetBrains Mono, and the 85%-marks variant Ghostty
# actually uses), write radar's managed blocks into ~/.config/herdr/config.toml,
# (re)start its daemon. Assumes the Herdr server is running and Ghostty's config
# already carries the "herdr-radar font block" (ghostty/config in this repo).

set -eu
REPO="${0:A:h:h}"
SRC="Binb1/awesome-tips/herdr/herdr-radar"
ID="hhdebb.herdr-radar"
CFG_DIR="$HOME/.config/herdr/plugins/config/$ID"
FONTS="$HOME/Library/Fonts"
TOOLS="$REPO/herdr/tools"

say() { printf '\033[1;33m==> %s\033[0m\n' "$1" }
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1 } }
need herdr; need node; need python3

ver=$(herdr --version | awk '{print $2}')
[[ "$(printf '%s\n0.9.0\n' "$ver" | sort -V | head -1)" == "0.9.0" ]] || { echo "herdr $ver < 0.9.0 (brew upgrade herdr, then restart the server)"; exit 1 }
[[ "$(herdr status server 2>/dev/null | awk '/^version:/{print $2}')" == "$ver" ]] || { echo "server is not $ver — restart it first (kills panes)"; exit 1 }
[[ "$(node -p 'process.versions.node.split(".")[0]')" -ge 18 ]] || { echo "node < 18"; exit 1 }

say "Plugin: install $SRC from GitHub"
herdr plugin action invoke state-stop --plugin "$ID" >/dev/null 2>&1 || true
herdr plugin unlink "$ID" >/dev/null 2>&1 || true   # older setups linked this checkout
herdr plugin uninstall "$ID" >/dev/null 2>&1 || true
herdr plugin install "$SRC" --ref main --yes >/dev/null
PLUGIN=$(herdr plugin list --plugin "$ID" --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).result.plugins[0].plugin_root))')
echo "    installed at $PLUGIN"

say "Settings: $CFG_DIR/config.toml"
mkdir -p "$CFG_DIR"
cp "$REPO/herdr/radar-config.toml" "$CFG_DIR/config.toml"

say "Fonts"
mkdir -p "$FONTS"
cp "$PLUGIN/dist/JetBrainsMonoHerdr-Regular.ttf" "$FONTS/"
if [[ ! -f "$FONTS/JetBrainsMonoHerdrSmall-Regular.ttf" || "$PLUGIN/dist/JetBrainsMonoHerdr-Regular.ttf" -nt "$FONTS/JetBrainsMonoHerdrSmall-Regular.ttf" ]]; then
  # fonttools in a private venv. Try each python until one can build a venv
  # with pip — a Homebrew python occasionally ships with ensurepip broken.
  VENV="$HOME/.cache/awesome-tips/fontenv"
  if [[ ! -x "$VENV/bin/python" ]]; then
    for py in python3.12 python3.13 python3.11 /usr/bin/python3 python3; do
      command -v "$py" >/dev/null 2>&1 || continue
      rm -rf "$VENV"
      "$py" -m venv "$VENV" >/dev/null 2>&1 && [[ -x "$VENV/bin/pip" ]] && break
    done
    [[ -x "$VENV/bin/pip" ]] || { echo "    could not create a python venv with pip"; exit 1 }
  fi
  "$VENV/bin/python" -c 'import fontTools' 2>/dev/null || "$VENV/bin/pip" install -q fonttools
  "$VENV/bin/python" "$TOOLS/shrink-radar-icons.py" \
    "$PLUGIN/dist/JetBrainsMonoHerdr-Regular.ttf" \
    "$FONTS/JetBrainsMonoHerdrSmall-Regular.ttf" 0.85 "JetBrains Mono Herdr Small"
else
  echo "    JetBrains Mono Herdr Small up to date"
fi

GHOSTTY="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [[ -f "$GHOSTTY" ]] && ! grep -q '^font-family = "JetBrains Mono Herdr Small"' "$GHOSTTY"; then
  echo "    WARNING: Ghostty config has no 'JetBrains Mono Herdr Small' font-family line —"
  echo "             copy ghostty/config from this repo (bootstrap step 3), then Cmd+Shift+,"
fi

say "Managed blocks + daemon"
(cd "$PLUGIN" && HERDR_PLUGIN_CONFIG_DIR="$CFG_DIR" node bin/configure.js --apply --reload)
herdr plugin action invoke state-stop  --plugin "$ID" >/dev/null 2>&1 || true
sleep 1
herdr plugin action invoke state-start --plugin "$ID" >/dev/null
sleep 3
pgrep -f "$PLUGIN/bin/agent-state.js" >/dev/null && echo "    daemon running" || { echo "    daemon NOT running — herdr plugin log --plugin $ID"; exit 1 }
herdr config check

say "Done. If the vendor marks look wrong, reload Ghostty (Cmd+Shift+,) or restart it for a new font file."
