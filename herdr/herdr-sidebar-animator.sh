#!/bin/sh
# Herdr sidebar spinner — resident animator (launchd: com.robin.herdr-sidebar-animator)
#
# Pushes a braille "circling dots" frame into the $spin pane-metadata token of
# every Claude pane whose agent_status is "working", ~2.5 fps. The sidebar
# renders it via [ui.sidebar.agents.rows_by_agent] in ~/.config/herdr/config.toml.
# Panes that stop working get the token cleared immediately; a 3s TTL cleans up
# if this process dies mid-spin.
#
# Source of truth: awesome-tips repo (herdr/herdr-sidebar-animator.sh).
# Live copy: ~/.config/herdr/herdr-sidebar-animator.sh (what launchd runs).
#
# Gotcha: `herdr pane report-metadata` wants the pane id FIRST and
# space-separated option values (its --help usage string is wrong, 0.8.2).

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export PATH

SRC="robin-spin"
TICK="0.4"
# Claude Code's signature sparkle pulse (grow then shrink)
FRAMES="·
✢
✳
✻
✽
✻
✳
✢"
NFRAMES=8

i=0
prev=""
while :; do
  # tr: keep the list space-separated so the `case " $panes "` membership
  # test below works (newline-separated lists never match its pattern)
  panes=$(herdr api snapshot 2>/dev/null \
    | jq -r '.result.snapshot.panes[]? | select(.agent=="claude") | select(.agent_status=="working") | .pane_id' 2>/dev/null \
    | tr '\n' ' ')
  panes=${panes% }

  if [ -n "$panes" ] || [ -n "$prev" ]; then
    i=$(( (i + 1) % NFRAMES ))
    frame=$(printf '%s\n' "$FRAMES" | sed -n "$((i + 1))p")

    for p in $panes; do
      herdr pane report-metadata "$p" --source "$SRC" \
        --token "spin=$frame" --ttl-ms 3000 >/dev/null 2>&1
    done

    # Clear panes that were spinning last tick but stopped working
    for p in $prev; do
      case " $panes " in *" $p "*) ;; *)
        herdr pane report-metadata "$p" --source "$SRC" \
          --clear-token spin >/dev/null 2>&1
      ;; esac
    done
  fi

  prev="$panes"
  # Idle backoff: nothing working -> poll lazily instead of at frame rate
  if [ -n "$panes" ]; then sleep "$TICK"; else sleep 2; fi
done
