# Herdr + Ghostty setup

Herdr is a tmux-style terminal multiplexer built for AI coding agents: a background
server owns all panes (they survive quitting Ghostty — or a reboot, as a layout
restore), and a sidebar shows each agent's live state (working / blocked / done /
idle). Ghostty is just a viewport; running `herdr` in any shell reattaches.

Hierarchy: **session** (isolation boundary) > **workspace** (one per project) >
**tab** (layout inside a project) > **pane** (one terminal).

Companion plugin: [herdr-palette](https://github.com/Binb1/herdr-palette) is a
command palette popup for Herdr — jump to workspaces and agents, run plugin
actions, run Herdr commands. `config.toml` binds it to `prefix+f` and `Cmd+P`.

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
mkdir -p ~/.config/ghostty/themes ~/.config/ghostty/icons
cp ghostty/themes/* ~/.config/ghostty/themes/
cp ghostty/icons/*.icns ~/.config/ghostty/icons/   # app icons; the SwiftBar
# plugin maintains the current.icns symlink these feed (dark: dracula,
# light: ayu-light)
ghostty +validate-config
# If Ghostty's in-app theme picker was ever used, it leaves an override at
# ~/Library/Application Support/com.mitchellh.ghostty/auto/theme.ghostty
# that silently wins over the config's theme line — delete it.

# 4. Claude Code integration (installs the agent-state hook + herdr skill)
herdr integration install claude
herdr integration status

# 4b. Optional: menu bar agent status + SSH toggle (see "Menu bar" below)
brew install --cask swiftbar
cp herdr/swiftbar/herdr.5s.sh ~/Documents/SwiftBar/   # or wherever SwiftBar's plugin folder is
cp herdr/swiftbar/ssh.30s.sh ~/Documents/SwiftBar/

# 5. Shell helpers — add to the end of ~/.zshrc
# h() { herdr --session "${1:-${PWD:t}}" }
#
# # Reassert the orange cursor at every prompt — ghostty loses theme/config
# # cursor colors on light/dark appearance switches (ghostty #12708)
# _orange_cursor() { printf '\e]12;#F8BC82\a' }
# precmd_functions+=(_orange_cursor)
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
| Shell helpers (`h` function + orange-cursor hook) | end of `~/.zshrc` |
| Ghostty custom themes (latte-custom / mocha-custom) | `~/.config/ghostty/themes/` |
| SwiftBar menu bar plugin | SwiftBar plugin folder (copy of `herdr/swiftbar/herdr.5s.sh`) |

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

## Theme

Ghostty follows the macOS appearance via
`theme = light:latte-custom,dark:mocha-custom` — two custom Catppuccin
variants in `~/.config/ghostty/themes/`:

- **mocha-custom** (dark): very dark `#151517` background, stock Mocha
  pastels slightly intensified, pink accents on palette 6/14.
- **latte-custom** (light): grey `#E0E0E3` background (not white), dark
  foreground for contrast, vivid max-saturation palette with soft pastel
  greens, orange selection.

The cursor is an orange (`#F8BC82`) blinking block in both modes. It is
deliberately defined in the main config, NOT the theme files, and
re-asserted by a zsh `precmd` hook — see "Known quirks".

Herdr's UI follows the Ghostty theme pairing automatically (`[theme]` in
`config.toml`): `auto_switch = true` tracks the terminal's light/dark
appearance, switching between `catppuccin-latte` (light) and `catppuccin`
Mocha (dark) — the same pair Ghostty uses. `panel_bg = "reset"` keeps the
pane area transparent so Ghostty's real background shows through (the
mocha-custom very-dark `#151517` in dark mode, the latte-custom grey
`#E0E0E3` in light) instead of Herdr repainting it with stock Catppuccin.

Limitation: `[theme.custom]` overrides apply in both modes (no
`theme.custom.dark`/`.light` as of 0.8.2), so the mocha-custom saturation
boost can't be mirrored onto the sidebar chrome without breaking light mode
— the sidebar stays stock Catppuccin.

## Menu bar (SwiftBar)

`swiftbar/herdr.5s.sh` is a SwiftBar plugin that shows agent states in the
macOS menu bar — the thing the sidebar can't do when Ghostty is hidden.

- **Icon**: the sheep, plus the loudest state — `🐑 ❗N` agents blocked
  (need input) > `🐑 ✓ N` done > `🐑 N` working > `🐑` all idle > `🐑 –`
  server not running.
- **Dropdown**: one row per agent (colored status dot, workspace label,
  pane title); clicking a row focuses that workspace and raises Ghostty.
- **Ghostty icon switching**: each poll checks macOS appearance and
  repoints `~/.config/ghostty/icons/current.icns` (dark → dracula,
  light → ayu-light), then triggers a Ghostty config reload via
  AppleScript so the Dock icon updates live. Ghostty's `light:`/`dark:`
  config syntax is theme-only, hence the symlink. First run prompts once
  to allow SwiftBar to control Ghostty.
- **Auto-numbering**: each poll also keeps workspace labels prefixed with
  their positional number (see "Workspace numbers" below) — new workspaces
  get their `N. ` prefix within one refresh, and prefixes are fixed up
  after a close shifts positions. The base name after `N. ` is untouched,
  so manual renames survive.

Data comes from `herdr api snapshot` (polled; the `.5s.` in the filename is
the interval — rename to change it), clicks go through
`herdr workspace focus`, renumbering through `herdr workspace rename`.
Needs `jq`. Covers the default session only.

Setup: `brew install --cask swiftbar`, launch it once to pick a plugin
folder, copy the script there, make sure it's executable. Edits to the copy
apply on the next refresh.

### SSH companion (`swiftbar/ssh.30s.sh`)

Shows whether the Mac is reachable for the phone-piloting flow (ssh or mosh
in from the phone, run `herdr` — see "Piloting from a phone" below):

- **Icon**: one laptop-lock glyph in every state — open lock (gray) =
  Remote Login on, no one connected; open lock (green) + count = active
  sessions (ssh + mosh); closed lock = Remote Login off; closed lock
  (orange) + count = Remote Login off but mosh sessions still alive (an
  established mosh session survives sshd being turned off — the icon
  won't claim "unreachable" while a phone is still attached).
- **Dropdown**, top to bottom: Remote Login status + LAN IP, Tailscale
  status + tailnet IP (green when up, gray when off / not installed), an
  "Active connections: N" count, then one row per connected ssh client
  (user + source host, from `who`) and a "via mosh × N" row for mosh
  sessions. Below that, copy rows — "Copy: mosh/ssh user@tailnet-ip" when
  Tailscale is up, plus the "(LAN)" variants — and a Turn SSH on/off
  toggle. The toggle drives sshd via `launchctl enable/disable +
  bootstrap/bootout` behind macOS's admin-password dialog (osascript). It
  deliberately avoids `systemsetup -setremotelogin`, which requires Full
  Disk Access on top of root (macOS 13+) and fails silently from SwiftBar.
  Toggle failures surface as a notification.

No dependencies; the on/off check is just "is anything listening on
localhost:22" (`nc`), which needs no privileges. Mosh sessions are counted
as mosh-server processes reparented to PID 1 — a real session runs
detached (ppid 1, no controlling tty), exactly one such process per
session. Neither `who` nor a tty check sees them, and a raw pgrep
double-counts locally spawned servers.

Mosh is connectionless, so the server genuinely cannot tell a suspended
phone from a dead client — and mosh-server never exits when a client
silently vanishes, so stale servers pile up across hard reconnects. The
plugin handles both honestly: it samples per-process byte counters
(nettop) each poll and diffs against the previous poll (state file in
`~/.cache/swiftbar-ssh30s.mosh`), marking each session **active** (green,
traffic since last poll) or **quiet** (gray — suspended phone or stale
server, with its uptime shown). The menu bar shows the active count in
green, or the total in gray when everything is quiet. With more than one
mosh session, a "Kill all but newest mosh session" row cleans up — safe,
since panes live in the Herdr server and a phone just reconnects fresh. Tailscale detection tries the CLI (GUI
app bundle, then brew paths) and falls back to spotting the 100.x CGNAT
address on a utun interface; the CLI call is capped at 3s via a perl
alarm because the GUI app's CLI hangs when the daemon isn't running
(macOS ships no `timeout`).

## Piloting from a phone

No app needed — the Herdr session server keeps panes alive, so any SSH
client attaches to the same session. Prefer **mosh** over plain ssh from a
phone: the connection survives the phone locking, Wi-Fi↔cellular switches,
and IP roaming, and predictive local echo makes typing feel instant on a
laggy link. The division of labor: Herdr keeps the *panes* alive, mosh
keeps the *connection* alive.

1. Mac: enable Remote Login (System Settings → General → Sharing, or the
   SwiftBar toggle) and `brew install mosh`. Mosh bootstraps over ssh
   (auth, keys), then hands off to `mosh-server` on UDP 60000–61000 — so
   Remote Login stays the master switch; the macOS application firewall
   may prompt once to allow `mosh-server`.
2. Phone (same Wi-Fi or tailnet): a mosh-capable client — Blink has the
   best mosh support, Termius works too — then `mosh <user>@<mac-ip>` and
   `herdr` (the SwiftBar dropdown has copy rows for both the tailnet and
   LAN address; prefer the tailnet one, it works from anywhere and
   survives switching networks). The TUI adapts to narrow screens. Plain
   `ssh` still works from any client.
3. Detach with `Ctrl+B q`; reattach later from anywhere with `herdr`.

Mosh caveats: no port/agent forwarding (fall back to ssh for tunnels), and
no native scrollback — irrelevant inside Herdr, which scrolls itself. Note
an established mosh session outlives the SSH toggle being turned off (it's
independent UDP once bootstrapped); the SwiftBar icon shows an orange
closed-lock count for that state.

Hardening: restrict Remote Login to your user in the Sharing pane, prefer
key auth over passwords, never port-forward 22 (or the mosh UDP range) on
the router — use Tailscale for access beyond the LAN.

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
the labels: "1. Fodmap", "2. awesome-tips". Numbers are positional: closing a
workspace shifts the ones after it.

The SwiftBar plugin maintains these prefixes automatically on every poll
(new workspaces get numbered, stale prefixes get fixed after a close). To
rename a workspace, change only the part after `N. ` — via `Ctrl+B Shift+W`
or `herdr workspace rename <id>` (`herdr workspace list` shows ids); the
plugin re-asserts the number prefix and leaves the rest alone. Without
SwiftBar running, prefixes are manual again.

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
- Ghostty loses cursor colors on light/dark appearance switches
  ([ghostty #12708](https://github.com/ghostty-org/ghostty/discussions/12708))
  — even config-level `cursor-color` gets wiped on a dark→light flip. Hence
  the belt-and-suspenders setup: cursor pinned in the main config (initial
  state) plus the `_orange_cursor` zsh precmd hook re-stamping it via OSC 12
  at every prompt. If the cursor ever turns black, run
  `printf '\e]112\a\e[0 q'` or just open a new prompt.
- Ghostty's cursor and selection colors only apply where Ghostty renders
  them: plain shell prompts. TUI apps (Claude Code, vim, ...) draw their own
  cursor and selection highlight — the blue selection inside Claude Code is
  Claude Code's, not the theme's. The hollow-outline cursor is just
  Ghostty's unfocused-window style, not a bug.
- If Ghostty's in-app theme picker was ever used, it leaves
  `~/Library/Application Support/com.mitchellh.ghostty/auto/theme.ghostty`
  behind, which silently overrides the config's `theme` line — delete it.
