#!/bin/sh
# Custom hook (NOT managed by herdr — lives beside herdr-agent-state.sh on purpose).
# Feeds display-only $branch and $worker tokens to the Herdr sidebar
# (rendered by [ui.sidebar.agents.rows_by_agent] in ~/.config/herdr/config.toml).
#
# Events (registered in ~/.claude/settings.json):
#   SessionStart / Stop        -> refresh $branch from the pane's git branch
#   PreToolUse (Task|Agent)    -> set $worker to the subagent description (15 min TTL)
#   SubagentStop / Stop        -> clear $worker
#
# Gotcha: `herdr pane report-metadata` wants the pane id FIRST and
# space-separated option values — the --help usage string is wrong (0.8.2).

set -u

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || input=""
[ -n "$input" ] || exit 0

event=$(printf '%s' "$input" | jq -r '.hook_event_name // ""' 2>/dev/null) || exit 0
# Ignore events fired inside a subagent's own session — except SubagentStop,
# which is delivered to the parent but carries the stopped subagent's agent_id.
agent_id=$(printf '%s' "$input" | jq -r '.agent_id // ""' 2>/dev/null) || exit 0
if [ -n "$agent_id" ] && [ "$event" != "SubagentStop" ]; then exit 0; fi

SRC="robin-sidebar"
PANE="$HERDR_PANE_ID"

report() {
  # report <args...> — never let a herdr failure surface as a hook error
  herdr pane report-metadata "$PANE" --source "$SRC" "$@" >/dev/null 2>&1 || true
}

case "$event" in
  SessionStart|Stop)
    cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null)
    branch=""
    [ -n "$cwd" ] && branch=$(git -C "$cwd" branch --show-current 2>/dev/null) || true
    # Default branches are noise — only a feature branch earns the orange line
    case "$branch" in main|master) branch="" ;; esac
    if [ -n "$branch" ]; then
      report --token "branch=⎇ $branch"
    else
      report --clear-token branch
    fi
    ;;
esac

case "$event" in
  PreToolUse)
    tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
    case "$tool" in Task|Agent) ;; *) exit 0 ;; esac
    desc=$(printf '%s' "$input" | jq -r '.tool_input.description // "subagent"' 2>/dev/null)
    report --token "worker=└ ✳ Worker: $desc" --ttl-ms 900000
    ;;
  SubagentStop|Stop)
    report --clear-token worker
    ;;
esac

exit 0
