# Claude Code status line

A compact one-line status line showing project, model, worktree, branch + git status, context window, the Claude.ai weekly limit and, right-aligned, Remote Control status:

```
awesome-tips  Opus 5.5·high  ⎇ main ↑1 ~2  ctx ██░░░ 42% (84k)  wk ███░░ 67%                    rc
awesome-tips  Opus 5.5·high  wt my-feature  ⎇ fix/login  ctx ░░░░░ 0% (0)  wk ███░░ 67%        rc
```

| Segment | Source field |
|---|---|
| `awesome-tips` | project: the main repo's folder name (the same from any of its worktrees), or the current folder outside git |
| `Opus 5.5·high` | `model.display_name`, `effort.level` |
| `wt my-feature` | linked git worktree folder name, only shown inside one (works for herdr, `claude --worktree` or plain `git worktree`) |
| `⎇ main` | current git branch of `workspace.current_dir`, hidden when it equals the worktree name |
| `↑1 ↓2 +1 ~3 ?1` | commits ahead/behind upstream, staged, modified and untracked files (only non-zero counts shown) |
| `ctx` | bar from `context_window.used_percentage`, then the percentage and, dimmed, tokens in context (`current_usage` input + cache creation + cache read, as `870` / `84k` / `1.2M`) |
| `wk` | `rate_limits.seven_day.used_percentage` (weekly limit). Claude Code only sends it after a session's first response, so the last value is cached in `~/.cache/claude-statusline/weekly` and shown until then (or until its `resets_at` passes) |
| `rc` | Remote Control: green when connected, red when not, right-aligned using `$COLUMNS`. Not in the status line JSON: read from the `bridgeSessionId` Claude Code writes to `~/.claude/sessions/<pid>.json` while RC is connected (undocumented, may change) |

In narrow panes the line drops its least important parts until it fits `$COLUMNS`, in this order: effort level, then worktree/branch names shortened with `…` one char at a time (down to 8), git counts, the branch (the worktree name can shrink again), then the worktree name. Project, model, both bars and `rc` always stay.

```
110 cols  awesome-tips  Opus 5.5·medium  ⎇ claude-code-statusline ~2  ctx ░░░░░ 9% (87k)  wk ██░░░ 31%              rc
 85 cols  awesome-tips  Opus 5.5  ⎇ claude-code-sta… ~2  ctx ░░░░░ 9% (87k)  wk ██░░░ 31%  rc
 75 cols  awesome-tips  Opus 5.5  ⎇ claude-…  ctx ░░░░░ 9% (87k)  wk ██░░░ 31%   rc
 66 cols  awesome-tips  Opus 5.5  ctx ░░░░░ 9% (87k)  wk ██░░░ 31%      rc
```

Bars turn green → yellow (50%) → red (80%). Both bars are always shown, at 0% until there's a value (`ctx` fills after the first response; `wk` starts from the cached value and needs a Claude.ai subscription).

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
- Drop order for narrow panes: the `render` calls at the end of the script (`render <effort> <wt max> <branch max> <counts>`).
- Colour thresholds: the `pct < 50` / `pct < 80` checks in `bar()`.
- Try it without Claude Code:
  ```sh
  echo '{"model":{"display_name":"Opus 5.5"},"context_window":{"used_percentage":42},"rate_limits":{"seven_day":{"used_percentage":67}}}' | ./statusline.sh
  ```
