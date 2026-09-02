#!/bin/bash
# <xbar.title>Herdr Agents</xbar.title>
# <xbar.desc>Menu bar status for Herdr agents: working / blocked / done at a glance, click to jump.</xbar.desc>
# <xbar.dependencies>herdr,jq</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
#
# Install: brew install --cask swiftbar, then copy this file into the SwiftBar
# plugin folder (chosen on first launch). The .5s. in the filename is the
# polling interval — rename to taste (herdr.2s.sh, herdr.30s.sh, ...).

HERDR="${HERDR_BIN:-/opt/homebrew/bin/herdr}"
JQ="$(command -v jq || echo /usr/bin/jq)"

# Click handler: SwiftBar re-runs this script as "$0 focus <workspace_id>"
if [ "$1" = "focus" ]; then
  "$HERDR" workspace focus "$2" >/dev/null 2>&1
  /usr/bin/osascript -e 'tell application "Ghostty" to activate' >/dev/null 2>&1
  exit 0
fi

SNAP="$("$HERDR" api snapshot 2>/dev/null)"
if [ -z "$SNAP" ]; then
  echo "🐑 –"
  echo "---"
  echo "Herdr server not running | color=gray"
  exit 0
fi

# Icon line: loudest state wins — blocked (needs you) > done > working > idle
echo "$SNAP" | "$JQ" -r '
  .result.snapshot.agents as $a |
  ([$a[] | select(.agent_status=="blocked")] | length) as $blocked |
  ([$a[] | select(.agent_status=="done")]    | length) as $done |
  ([$a[] | select(.agent_status=="working")] | length) as $working |
  if   $blocked > 0 then "🔴 \($blocked)"
  elif $done    > 0 then "🟢 \($done)"
  elif $working > 0 then "🐑 \($working)"
  else "🐑" end'

echo "---"

# One clickable row per agent: status glyph + workspace label + pane title.
# "|" is SwiftBar's field separator, so strip it from titles.
echo "$SNAP" | "$JQ" -r --arg self "$0" '
  .result.snapshot as $s |
  ($s.workspaces | map({(.workspace_id): .label}) | add // {}) as $labels |
  if ($s.agents | length) == 0 then "No agents running | color=gray"
  else $s.agents[] |
    (if   .agent_status=="working" then "🟠"
     elif .agent_status=="blocked" then "🔴"
     elif .agent_status=="done"    then "🟢"
     elif .agent_status=="idle"    then "⚪️"
     else "❔" end) as $glyph |
    ((.terminal_title_stripped // "") | gsub("\\|"; "/") | .[0:48]) as $title |
    "\($glyph) \($labels[.workspace_id] // .workspace_id)\(if $title != "" then " — " + $title else "" end) | bash=\"\($self)\" param1=focus param2=\(.workspace_id) terminal=false refresh=true"
  end'
