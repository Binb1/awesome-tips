#!/bin/bash
# <xbar.title>Herdr Agents</xbar.title>
# <xbar.desc>Menu bar status for Herdr agents: working / blocked / done at a glance, click to jump.</xbar.desc>
# <xbar.dependencies>herdr,jq</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
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
  echo ":xmark.circle: | sfsize=15"
  echo "---"
  echo "Herdr server not running | color=gray"
  exit 0
fi

# Menu bar item: monochrome SF Symbol (template-rendered, matches the other
# menu extras) + a count. Loudest state wins: blocked (needs you) > done >
# working > all idle.
echo "$SNAP" | "$JQ" -r '
  .result.snapshot.agents as $a |
  ([$a[] | select(.agent_status=="blocked")] | length) as $blocked |
  ([$a[] | select(.agent_status=="done")]    | length) as $done |
  ([$a[] | select(.agent_status=="working")] | length) as $working |
  if   $blocked > 0 then ":exclamationmark.circle.fill: \($blocked)"
  elif $done    > 0 then ":checkmark.circle: \($done)"
  elif $working > 0 then ":arrow.triangle.2.circlepath: \($working)"
  else ":moon.zzz:" end
  + " | sfsize=15"'

echo "---"

# One row per agent: colored SF Symbol dot + workspace label + pane title.
# Clicking focuses the workspace and raises Ghostty.
# "|" is SwiftBar's field separator, so strip it from titles; long UUIDs in
# titles (Claude resume sessions) are elided.
echo "$SNAP" | "$JQ" -r --arg self "$0" '
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
      | gsub("\\|"; "/")
      | gsub("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"; "…")
      | .[0:44]) as $title |
    "\($labels[.workspace_id] // .workspace_id)\(if $title != "" then "  ·  " + $title else "" end)"
    + " | sfimage=\($sym[0]) sfcolor=\($sym[1]) sfsize=12 size=13"
    + " bash=\"\($self)\" param1=focus param2=\(.workspace_id) terminal=false refresh=true"
  end'
