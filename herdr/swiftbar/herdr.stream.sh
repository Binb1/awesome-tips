#!/bin/bash
# <xbar.title>Herdr Agents</xbar.title>
# <xbar.desc>Menu bar status for Herdr agents: working / blocked / done at a glance, click to jump. Animated spinner while agents work.</xbar.desc>
# <xbar.dependencies>herdr,jq</xbar.dependencies>
# <swiftbar.type>streamable</swiftbar.type>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
#
# Install: brew install --cask swiftbar, then copy this file into the SwiftBar
# plugin folder (chosen on first launch). This is a STREAMABLE plugin: SwiftBar
# keeps it running and it pushes a new menu (preceded by a "~~~" line) whenever
# something changes. That's what lets the spinner animate at SPIN_TICK fps
# while herdr is only polled every POLL ticks — a plain interval plugin would
# need a 0.5s filename interval and re-run jq/herdr at frame rate.

HERDR="${HERDR_BIN:-/opt/homebrew/bin/herdr}"
JQ="$(command -v jq || echo /usr/bin/jq)"

# Click handler: SwiftBar re-runs this script as "$0 focus <workspace_id>".
# Must exit before the streaming loop — this is a fresh process, not the
# resident one. No refresh=true needed: the resident loop picks the state
# change up on its next poll.
if [ "$1" = "focus" ]; then
  "$HERDR" workspace focus "$2" >/dev/null 2>&1
  /usr/bin/osascript -e 'tell application "Ghostty" to activate' >/dev/null 2>&1
  exit 0
fi

SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)   # array, not string slicing — byte-safe in any locale
SPIN_TICK=0.5                    # seconds per frame
POLL=10                          # snapshot/housekeeping every POLL ticks (= 5s)

ghostty_icon_pass() {
  # Ghostty app icon follows macOS appearance (ghostty has no light:/dark:
  # syntax for macos-custom-icon, so the config points at a current.icns
  # symlink and this pass repoints it): dark -> dracula, light -> ayu-light,
  # then ask ghostty to reload config so the new icon applies live.
  local icons="$HOME/.config/ghostty/icons" want
  [ -d "$icons" ] || return 0
  if /usr/bin/defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
    want="$icons/dracula.icns"
  else
    want="$icons/ayu-light.icns"
  fi
  if [ -f "$want" ] && [ "$(readlink "$icons/current.icns")" != "$want" ]; then
    ln -sfn "$want" "$icons/current.icns"
    /usr/bin/osascript -e 'tell application "Ghostty" to perform action "reload_config" on first terminal' >/dev/null 2>&1
  fi
}

poll_herdr() {
  # Refreshes NB/ND/NW (blocked/done/working counts) and MENU (dropdown body).
  SNAP="$("$HERDR" api snapshot 2>/dev/null)"
  if [ -z "$SNAP" ]; then
    NB=0; ND=0; NW=0; SERVER_UP=0
    MENU="Herdr server not running | color=gray"
    return
  fi
  SERVER_UP=1

  # Auto-numbering: keep every workspace label prefixed with its positional
  # number ("3. awesome-tips"). Herdr's sidebar can't render numbers (0.8.2),
  # so the number lives in the label — this pass renames any workspace whose
  # prefix is missing or stale (new workspace, or positions shifted after a
  # close). The base name (anything after "N. ") is preserved, so manual
  # renames survive; only the prefix is maintained.
  local renames wid newlabel
  renames="$(echo "$SNAP" | "$JQ" -r '.result.snapshot.workspaces[]
    | (.label | sub("^[0-9]+\\.\\s*"; "")) as $base
    | select(.label != "\(.number). \($base)")
    | "\(.workspace_id)\t\(.number). \($base)"')"
  if [ -n "$renames" ]; then
    while IFS=$'\t' read -r wid newlabel; do
      [ -n "$wid" ] && "$HERDR" workspace rename "$wid" "$newlabel" >/dev/null 2>&1
    done <<<"$renames"
    SNAP="$("$HERDR" api snapshot 2>/dev/null)"
  fi

  read -r NB ND NW <<<"$(echo "$SNAP" | "$JQ" -r '
    .result.snapshot.agents as $a |
    "\([$a[] | select(.agent_status=="blocked")] | length) \([$a[] | select(.agent_status=="done")] | length) \([$a[] | select(.agent_status=="working")] | length)"')"

  # One row per agent: colored SF Symbol dot + workspace label + pane title.
  # Clicking focuses the workspace and raises Ghostty.
  # "|" is SwiftBar's field separator and newlines start a new menu row, so
  # strip both from titles AND labels — labels are attacker-influenced (any
  # agent in a pane can run `herdr workspace rename`), and an unsanitized
  # "|" would let a renamed workspace inject SwiftBar click-action params
  # (href=/bash=) into its own row. Long UUIDs in titles are elided.
  MENU="$(echo "$SNAP" | "$JQ" -r --arg self "$0" '
    .result.snapshot as $s |
    ($s.workspaces | map({(.workspace_id): .label}) | add // {}) as $labels |
    if ($s.agents | length) == 0 then "No agents running | color=gray"
    else $s.agents[] |
      (if   .agent_status=="working" then ["circle.fill",        "#E8A33D"]
       elif .agent_status=="blocked" then ["exclamationmark.circle.fill", "#E35D6A"]
       elif .agent_status=="done"    then ["checkmark.circle.fill", "#5BB974"]
       elif .agent_status=="idle"    then ["circle",              "#98989D"]
       else                               ["questionmark.circle", "#98989D"] end) as $sym |
      ((.terminal_title_stripped // "")
        | gsub("[|\r\n]"; "/")
        | gsub("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"; "…")
        | .[0:44]) as $title |
      (($labels[.workspace_id] // .workspace_id)
        | gsub("[|\r\n]"; "/")
        | .[0:44]) as $label |
      "\($label)\(if $title != "" then "  ·  " + $title else "" end)"
      + " | sfimage=\($sym[0]) sfcolor=\($sym[1]) sfsize=12 size=13"
      + " bash=\"\($self)\" param1=focus param2=\(.workspace_id) terminal=false"
    end')"
}

# Streaming loop: push a block only when it differs from the last one — idle
# means zero emissions, working means one per frame (the spinner advances).
LAST=""
i=0
while :; do
  if (( i % POLL == 0 )); then
    ghostty_icon_pass
    poll_herdr
  fi

  # Menu bar item: the sheep, plus the loudest state — blocked (needs you) >
  # done > working (spinner) > all idle.
  if [ "$SERVER_UP" != 1 ]; then
    BAR="🐑 –"
  elif [ "$NB" -gt 0 ]; then
    BAR="🐑 ❗$NB"
  elif [ "$ND" -gt 0 ]; then
    BAR="🐑 ✓ $ND"
  elif [ "$NW" -gt 0 ]; then
    BAR="🐑 ${SPIN[i % 10]} $NW"
  else
    BAR="🐑"
  fi

  BLOCK="$BAR
---
$MENU"
  if [ "$BLOCK" != "$LAST" ]; then
    printf '~~~\n%s\n' "$BLOCK"
    LAST="$BLOCK"
  fi

  sleep "$SPIN_TICK"
  i=$((i + 1))
done
