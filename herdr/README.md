# Herdr + Ghostty setup

Herdr is a tmux-style terminal multiplexer built for AI coding agents: a background
server owns all panes (they survive quitting Ghostty — or a reboot, as a layout
restore), and a sidebar shows each agent's live state (working / blocked / done /
idle). Ghostty is just a viewport; running `herdr` in any shell reattaches.

Hierarchy: **session** (isolation boundary) > **workspace** (one per project) >
**tab** (layout inside a project) > **pane** (one terminal).

## Bootstrap a new machine

```bash
# 1. Install Herdr (0.8.2+)
brew install herdr

# 2. Herdr config
mkdir -p ~/.config/herdr
cp herdr/config.toml ~/.config/herdr/config.toml

# 3. Ghostty config (includes the Herdr keybinds at the bottom)
#    + custom light/dark themes (latte-custom / mocha-custom)
cp ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config
mkdir -p ~/.config/ghostty/themes
cp ghostty/themes/* ~/.config/ghostty/themes/
ghostty +validate-config
# If Ghostty's in-app theme picker was ever used, it leaves an override at
# ~/Library/Application Support/com.mitchellh.ghostty/auto/theme.ghostty
# that silently wins over the config's theme line — delete it.

# 4. Claude Code integration (installs the agent-state hook + herdr skill)
herdr integration install claude
herdr integration status

# 5. Shell helper — add to the end of ~/.zshrc
# h() { herdr --session "${1:-${PWD:t}}" }
```

Restart Ghostty fully after copying the config (keybinds and icon need it, a
config reload is not enough).

## Where everything lives

| Thing | Location |
|---|---|
| Herdr binary (Homebrew) | `/opt/homebrew/bin/herdr` |
| Herdr config | `~/.config/herdr/config.toml` |
| Herdr logs, session state, socket | `~/.config/herdr/` |
| Ghostty config (keybinds at the bottom) | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| Claude Code integration hook (feeds agent states) | `~/.claude/hooks/herdr-agent-state.sh` |
| Herdr skill for Claude Code | `~/.claude/skills/herdr` |
| `h` shell function | end of `~/.zshrc` |

The hook and the skill are managed by `herdr integration` — don't edit them,
reinstalling overwrites both.

## Keybinding scheme

Grammar: **Cmd = Herdr workspaces, Cmd+Opt = Herdr tabs, Opt/Shift layers =
native Ghostty, Ctrl+B = Herdr prefix for everything else.**

| Chord | Action |
|---|---|
| `Cmd+T` | New Herdr workspace |
| `Cmd+1..9` | Jump to Herdr workspace N |
| `Cmd+Opt+T` | New Herdr tab (prompts for a name) |
| `Cmd+Opt+1..9` or `Opt+1..9` | Jump to Herdr tab N |
| `Cmd+D` / `Cmd+Shift+D` | Split pane right / down |
| `Cmd+Opt+arrows` | Move between panes |
| `Cmd+Shift+T` | Native Ghostty tab (plain shell, no Herdr) |
| `Opt+Shift+1..9` | Native Ghostty tab N (not Cmd+Shift — those are macOS screenshot keys) |
| `Cmd+Ctrl+D` / `Cmd+Ctrl+Shift+D` | Native Ghostty split right / down |
| `Cmd+Shift+Opt+arrows` | Move between native Ghostty splits |
| `Ctrl+B` then `?` | Full Herdr keymap help |
| `Ctrl+B` then `z` / `x` / `w` / `g` / `b` / `q` | Zoom pane / close pane / workspace picker / goto / sidebar / detach |

How it works: the Ghostty keybinds send raw text sequences (`\x02` = Ctrl+B,
Herdr's prefix key), so Cmd muscle memory drives Herdr. Digit keys are bound to
physical `digit_N` triggers so they work across keyboard layouts.

Herdr-side remap in `config.toml`: `switch_workspace = "prefix+1..9"`
(workspaces took the plain digits), `switch_tab = "alt+1..9"` (direct chord,
esc+digit encoding — this is why plain `Opt+digit` also jumps tabs, since
Ghostty sets `macos-option-as-alt = true`).

## Sessions and the `h` function

`h` in any project directory attaches to a session named after the folder
(`h` in Fodmap runs `herdr --session Fodmap`; `h scratch` names it explicitly).
Default layout: one session, one workspace per project. Named sessions are for
hard isolation; each gets its own sidebar. `herdr session list` shows them,
`herdr session stop <name>` kills one (panes and all).

Gotcha: you cannot run `h` from inside a Herdr pane (nested guard). Detach
first (`Ctrl+B q`) or use a native Ghostty tab (`Cmd+Shift+T`).

## Workspace numbers

The sidebar cannot render workspace numbers (checked 0.8.2), so numbers live in
the labels: "1. Fodmap", "2. awesome-tips". Rename with `Ctrl+B Shift+W` or
`herdr workspace rename <id>` (`herdr workspace list` shows ids). Numbers are
positional: closing a workspace shifts the ones after it, so renumber after
closing.

## Useful commands

```bash
herdr                        # attach (or start) the default session
herdr status                 # client/server health
herdr session list           # all sessions
herdr workspace list         # workspaces + agent states + numbers
herdr integration status     # agent integrations (hook + skill installed)
herdr server reload-config   # apply config.toml changes
herdr server stop            # kill the server (all sessions!)
ghostty +validate-config     # check ghostty config after edits
ghostty +show-config | grep keybind   # effective bindings (spot stale physical defaults)
```

## Known quirks

- Remapped Cmd keys send raw control sequences: in a shell without Herdr
  attached, `Cmd+D` etc. type garbage. Live inside Herdr or use the Shift/Ctrl
  native layers.
- `Cmd+Opt+digit` was flaky in one Ghostty instance even though the config
  parses correctly; plain `Opt+digit` always works. If a full Ghostty restart
  doesn't fix it, `Opt+digit` is the reliable tab jump.
- If the Herdr **server** restarts, layout is restored but running processes
  are not (panes reopen as fresh shells in their directories). Normal
  detach/quit of Ghostty loses nothing.
- Optional extras are commented out at the bottom of the Ghostty config:
  `Cmd+Shift+Enter` zoom, `Cmd+W` close pane (would lose Ghostty close-tab).
