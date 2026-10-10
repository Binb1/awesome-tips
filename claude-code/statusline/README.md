# Claude Code status line

A compact one-line status line showing project, model, worktree, branch + git status, context window, the Claude.ai weekly limit and, right-aligned, Remote Control status:

```
awesome-tips  Opus 5.5·high  main ↑1 ~2  ctx ██░░░ 42%  wk ███░░ 67%                    rc on
awesome-tips  Opus 5.5·high  wt my-feature  fix/login  ctx ░░░░░ 0%  wk ███░░ 67%       rc off
```

| Segment | Source field |
|---|---|
| `awesome-tips` | project: the main repo's folder name (the same from any of its worktrees), or the current folder outside git |
| `Opus 5.5·high` | `model.display_name`, `effort.level` |
| `wt my-feature` | linked git worktree folder name, only shown inside one (works for herdr, `claude --worktree` or plain `git worktree`) |
| `main` | current git branch of `workspace.current_dir`, hidden when it equals the worktree name |
| `↑1 ↓2 +1 ~3 ?1` | commits ahead/behind upstream, staged, modified and untracked files (only non-zero counts shown) |
| `ctx` | `context_window.used_percentage` |
| `wk` | `rate_limits.seven_day.used_percentage` (weekly limit) |
| `rc on` / `rc off` | Remote Control, right-aligned using `$COLUMNS`. Not in the status line JSON: read from the `bridgeSessionId` Claude Code writes to `~/.claude/sessions/<pid>.json` while RC is connected (undocumented, may change) |

Bars turn green → yellow (50%) → red (80%). Both bars are always shown, at 0% until Claude Code reports a value (`ctx` fills after the first response; `wk` needs a Claude.ai subscription).

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
