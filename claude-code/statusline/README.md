# Claude Code status line

A compact one-line status line showing model, branch, context window and Claude.ai usage limits:

```
Opus 5.5·high  main  ctx ██░░░ 42%  5h ██░░░ 31%  wk ███░░ 67%
```

| Segment | Source field |
|---|---|
| `Opus 5.5·high` | `model.display_name`, `effort.level` |
| `main` | current git branch of `workspace.current_dir` |
| `ctx` | `context_window.used_percentage` |
| `5h` | `rate_limits.five_hour.used_percentage` |
| `wk` | `rate_limits.seven_day.used_percentage` (weekly limit) |

Bars turn green → yellow (50%) → red (80%). Segments with no data are hidden — e.g. `5h`/`wk` only appear on a Claude.ai subscription, and `ctx` after the first response.

## Setup

Needs `jq` (ships with macOS 15+ at `/usr/bin/jq`, otherwise `brew install jq`).

Point `~/.claude/settings.json` straight at the script in this repo, so a `git pull` is all it takes to update:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/Documents/projects/awesome-tips/claude-code/statusline/statusline.sh"
  }
}
```

## Tweaking

- Bar width: `width=5` in `bar()`.
- Colour thresholds: the `pct < 50` / `pct < 80` checks in `bar()`.
- Try it without Claude Code:
  ```sh
  echo '{"model":{"display_name":"Opus 5.5"},"context_window":{"used_percentage":42},"rate_limits":{"seven_day":{"used_percentage":67}}}' | ./statusline.sh
  ```
