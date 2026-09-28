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
# 1. Install Herdr (0.9.0+ — herdr-radar needs it)
brew install herdr

# 2. Herdr config
mkdir -p ~/.config/herdr
cp herdr/config.toml ~/.config/herdr/config.toml

# 2b. Sidebar: the vendored herdr-radar plugin (herdr/herdr-radar) with our
#     changes. Run AFTER step 3 (Ghostty config carries its font line) and
#     after step 4 (server must be 0.9.0+). Installs the plugin from GitHub,
#     then settings, fonts, blocks, daemon.
herdr/install-radar.sh

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
cp herdr/swiftbar/herdr.stream.sh ~/Documents/SwiftBar/   # or wherever SwiftBar's plugin folder is
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
| herdr-radar plugin settings (repo: `herdr/radar-config.toml`) | `~/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml` |
| herdr-radar plugin code (Herdr's own copy, installed from GitHub) + daemon state | `~/.config/herdr/plugins/github/hhdebb.herdr-radar-*/herdr/herdr-radar/`; `~/.local/state/herdr/plugins/hhdebb.herdr-radar/` |
| herdr-radar fonts | `~/Library/Fonts/JetBrainsMonoHerdr-Regular.ttf`, `JetBrainsMonoHerdrSmall-Regular.ttf` (generated), `HerdrAgentIconsMax-*.ttf` (radar's own, unused by Ghostty) |
| Herdr skill for Claude Code | `~/.claude/skills/herdr` |
| Shell helpers (`h` function + orange-cursor hook) | end of `~/.zshrc` |
| Ghostty custom themes (latte-custom / mocha-custom) | `~/.config/ghostty/themes/` |
| SwiftBar menu bar plugin | SwiftBar plugin folder (copy of `herdr/swiftbar/herdr.stream.sh`) |

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
- **latte-custom** (light): grey `#DCDCE1` background (not white), dark
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
`#DCDCE1` in light) instead of Herdr repainting it with stock Catppuccin.

The four chrome overrides (`panel_bg = "reset"`, `overlay0/1`, `teal`) live in
`[theme.custom.dark]` **and** `[theme.custom.light]` (same values in both —
0.9.0 added the per-appearance tables), not in a plain `[theme.custom]`: herdr-radar
owns that exact header and refuses to install while one exists by hand. Note
radar also rewrites `[theme]` itself (`name = …`, `auto_switch = false`) — see
the radar section. Since the
tables are per-mode now, the old 0.8.2 limitation is gone — a mocha-custom
saturation boost for the sidebar chrome could go in `.dark` alone without
touching light mode.

## Sidebar (herdr-radar, vendored with our changes)

The **whole sidebar** — `[ui.sidebar.agents]`, `rows_by_agent` and
`[ui.sidebar.spaces]` — plus `tab_bar_right` and `[theme.custom]` are rendered by
[herdr-radar](https://github.com/hhdebb/herdr-radar) through marker-fenced
managed blocks (`# >>> herdr-radar … block` / `# <<<`) in `config.toml`.
**Don't hand-write any of those tables**: radar refuses to install while one
exists outside its markers (`herdr: refused — [ui.sidebar.spaces] already
written by hand`), and it regenerates the blocks on every apply, so edits inside
the markers don't survive either. Settings popup: `prefix+,`.

The plugin is **vendored in this repo** at `herdr/herdr-radar/` — upstream
`hhdebb/herdr-radar@29160ad` as a `git subtree`, plus one commit with our
changes. It is **installed from GitHub** (`Binb1/awesome-tips/herdr/herdr-radar`
on `main`), not linked from the checkout: Herdr keeps its own copy, so switching
branches or moving this repo can't blank the sidebar. Upstream
hardcodes its palette and row shapes; everything under "Our changes" needed
code, not settings, and a new Mac should need nothing but this repo.

```bash
herdr/install-radar.sh   # Herdr 0.9.0+ server running, Node 18+
```

Idempotent — it installs the plugin from GitHub, installs `radar-config.toml`, installs
the two fonts (generating the 85%-marks one with fonttools in
`~/.cache/awesome-tips/fontenv`), writes radar's managed blocks and (re)starts
the daemon. **Re-run it after any change to the plugin code (push it to `main`
first — the install pulls from GitHub) or `radar-config.toml`** — the daemon reads settings once at start, and the row
shapes/colours live in the generated blocks. By hand, the pieces are:

```bash
herdr plugin install Binb1/awesome-tips/herdr/herdr-radar --ref main --yes
herdr plugin action invoke configure   --plugin hhdebb.herdr-radar   # blocks + reload
herdr plugin action invoke state-stop  --plugin hhdebb.herdr-radar
herdr plugin action invoke state-start --plugin hhdebb.herdr-radar   # daemon
```

The plugin id stays `hhdebb.herdr-radar` (it comes from the manifest). Pulling
upstream:

```bash
git subtree pull --prefix herdr/herdr-radar https://github.com/hhdebb/herdr-radar.git main --squash
# conflicts land in the five files under "Our changes"; then herdr/install-radar.sh
```

### Settings (`herdr/radar-config.toml`)

- `follow_appearance = true` — radar polls macOS appearance once a minute,
  drives `[theme] name` itself and sets `auto_switch = false` (Herdr's own switch
  only checks on attach). **Leave it on**: off, radar reads the mode from
  `[theme] name`, finds none, and builds the sidebar for *light* — near-black
  logo ink and light greys on a dark panel. That was the first thing that looked
  wrong after install.
- `group_gap = false` — no blank row between workspace groups.
- `[colors]` `active_row_bg_light = "#b9cdf2"` (radar's default, pinned) and
  `active_row_bg_dark = "#363b52"` (radar's `#414868` pops too hard on our
  `#151517` panel).
- `[chrome]` — **fork-only.** Extra `[theme.custom]` tokens written verbatim into
  radar's managed theme block: `panel_bg = "reset"` (transparent panels — without
  it the tab bar paints white), `overlay0/1` (readable dim text on both panels),
  `teal` (azure instead of Catppuccin teal on pane-border chips). They can't live
  anywhere else: radar owns `[theme.custom]`, and Herdr's `[theme.custom.light]`
  / `.dark` tables stop applying once `auto_switch` is false.

### Our changes (vs upstream `29160ad`)

| Where | What |
|---|---|
| `lib/config.js`, `lib/managed-config.js` | the `[chrome]` passthrough above |
| `lib/palette.js` | light-mode stale grey `#a4a5a9` → `#8e9097` (unreadable on the grey panel); light `idle_fresh` green `#416c4f` → `#4c9a5a`, same as `done` — one green, not two |
| `lib/managed-config.js` | working titles not bold; space name row = aggregate mark + name in the group-header style (bold `#7c7f93`), blue ring `#2E9BE0` for parked; then up to three **tab rows** (`logo · [mark] tab-name`) instead of upstream's vendor-logo row |
| `lib/state.js` | `space_names` split from the logo token; `spaceMark` = spinner / ✓ / ? / ring; `spaceTabTokens` — per-tab rows with the tab's own state, unnamed tabs take the lead agent's session title, empty unnamed tabs are dropped; `hot` paint |
| `lib/frame.js` | two-pass so a workspace with a working pane paints its parked siblings in the working colour ("hot"); any idle tier counts as idle for the space mark (upstream matched `idle` exactly and left fresh/stale-only workspaces unmarked); all-stale workspace takes the grey ring |

Row shapes, with Herdr's unsuppressible ` · ` between cells:

```
agents                              spaces
1. Fodmap                           ✓ · 1. Fodmap
   ✳ · ✓ ROBIN-83 recomm…              ✳ · ✓ ROBIN-83 recomm…
   └ · ✳ · MY FODMAP t…             ○ · 2. Fodmap Backend   (blue: parked < 2 h)
7. moqa-aso-bot  (stale: dim)          ✳ · Landing page
   ✳ · Claude Code                  ○ · 4. Dump-it          (grey: empty / all stale)
```

Marks: braille spinner in the vendor colour while working, `✓` green done, `?` red
blocked. Logo is brand orange in every state except stale. Idle → stale is
`activity_stale_minutes` (default 120).

Things that are **not** possible and were asked for more than once: smaller
text or glyphs (one cell each, Ghostty `font-size` is the only knob — the marks
themselves are handled by the font, see the Ghostty font block), removing or
narrowing the ` · ` cell separator (no Herdr setting; would be an upstream
Herdr request), two colours in one cell.

Uninstall is ordered: `herdr plugin action invoke unconfigure` (stops the daemon,
clears every token it wrote, removes the managed blocks) → `uninstall-font` →
`herdr plugin uninstall hhdebb.herdr-radar`.

The ghostty-theme-sync plugin is still installed but only its startup
`refresh.sh` runs (pane tokens). Its `sync` action rewrites `[theme.custom]` and
"every sidebar token fg" — don't invoke it any more, it would repaint radar's
managed block.

### What was removed, and why it can't come back as-is

Before radar (2026-09-14 → 2026-09-16) the sidebar was hand-rolled: a
`rows_by_agent` template with a `$spin` sparkle animator (launchd loop pushing
frames at 2.5 fps) and a Claude Code hook feeding `$branch` (feature branch,
orange) and `$worker` (`└ ✳ Worker: <subagent description>`) pane-metadata
tokens. All of it is gone: the animator because radar has a native spinner, the
tokens hook because radar's agent row is fully generated — no config hook for
extra cells, the title row already carries 14 of Herdr's 16-token row ceiling,
and the block is rewritten on every apply. There is no way to render a custom
token in radar's rows, so the hook was writing tokens nothing displayed.

If per-pane branch or subagent info is ever wanted back, it means either
`agents_panel = "herdr"` (lose radar entirely) or a patch upstream.

Gotchas from the token pipeline, still true for anything else that calls it:
- `herdr pane report-metadata` wants the pane id FIRST and space-separated
  option values — the `--help` usage string is wrong (0.8.2).
- Token values are whitespace-trimmed server-side (even NBSP), so worker
  rows carry a `└` prefix instead of indentation.
- SubagentStop is delivered to the parent session but carries the stopped
  subagent's `agent_id` — don't use "agent_id present" alone to filter out
  subagent-context events.

### Upgrading Herdr (0.8.2 → 0.9.0), the hard way

`brew upgrade herdr` relinks the binary but leaves the running server on the old
version, and 0.9.0's client can't speak 0.8.2's private protocol
(`herdr status server` → `private_protocol_compatible: no`). Symptoms: `herdr api
snapshot` returns nothing, and every hook that shells out to `herdr pane
report-metadata` fails silently. Panes survive — the old server keeps serving its
attached clients — but the CLI is blind until you restart the server, and a
restart kills every pane's processes (layout is restored, processes are not).

So: **capture what's running before you upgrade**, and don't drive the restart
from a Claude session that is itself living in a herdr pane (`$HERDR_PANE_ID`) —
it dies mid-swap. `herdr update --handoff` claims a live handoff, untested here
and it fights the brew install.

## Sidebar session-bar rows

The sidebar renders Claude panes as compact "session bar" entries
(`[ui.sidebar.agents.rows_by_agent]` in `config.toml`, Herdr 0.8.2+):

1. status glyph + Claude Code sparkle-pulse spinner while working (`$spin`,
   orange, frames ·✢✳✻✽) + the unstripped terminal title — it keeps the
   glyph Claude Code itself maintains (✳ idle, ◐ working),
2. one extra line only when it means something: git branch in orange
   (`$branch` — suppressed on main/master) and/or
   `└ ✳ Worker: <description>` while a subagent runs (`$worker`, dim).

`status_indicators = "dots"` keeps the state marks as uniform filled
color dots, same size in every state (the "symbols" set renders working as
a wide half-moon ◐, which looked off); `row_gap = 0` keeps entries tight. Custom per-state glyphs are
NOT natively supported (only the dots/symbols sets, checked 0.8.2) — the
spinner works because we own the token pipeline, not the state icon.

`$branch` / `$worker` are display-only pane metadata tokens fed by a custom
Claude Code hook, `~/.claude/hooks/herdr-sidebar-tokens.sh` (repo copy:
`herdr/herdr-sidebar-tokens.sh`), registered in
`~/.claude/settings.json` on SessionStart/Stop (branch), PreToolUse with
matcher `Task|Agent` (worker set, 15-min TTL) and SubagentStop (worker
clear). It lives *beside* the managed `herdr-agent-state.sh` — reinstalling
the herdr integration doesn't touch it. Needs `jq`.

`$spin` is animated by `herdr-sidebar-animator.sh` (repo copy here; live
copy `~/.config/herdr/herdr-sidebar-animator.sh`), a resident loop run by
launchd (`~/Library/LaunchAgents/com.robin.herdr-sidebar-animator.plist`,
repo copy: `herdr/com.robin.herdr-sidebar-animator.plist`, KeepAlive): every 0.4s it snapshots, pushes the next sparkle frame to every
working Claude pane (3s TTL so a dead animator can't freeze a frame), and
clears panes that stopped working; with nothing working it idles at 2s
polls. Manage with `launchctl bootstrap|bootout gui/$(id -u) <plist>`; log
at `/tmp/herdr-sidebar-animator.log`.

Gotchas learned building it:
- `herdr pane report-metadata` wants the pane id FIRST and space-separated
  option values — the `--help` usage string is wrong (0.8.2).
- Token values are whitespace-trimmed server-side (even NBSP), so worker
  rows carry a `└` prefix instead of indentation.
- SubagentStop is delivered to the parent session but carries the stopped
  subagent's `agent_id` — don't use "agent_id present" alone to filter out
  subagent-context events.

## Menu bar (SwiftBar)

`swiftbar/herdr.stream.sh` is a SwiftBar plugin that shows agent states in
the macOS menu bar — the thing the sidebar can't do when Ghostty is hidden.

- **Icon**: the sheep, plus the loudest state — `🐑 ❗N` agents blocked
  (need input) > `🐑 ✓ N` done > `🐑 ⠧ N` working (animated spinner) >
  `🐑` all idle > `🐑 –` server not running.
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

This is a SwiftBar **streamable** plugin (`<swiftbar.type>streamable</swiftbar.type>`):
SwiftBar keeps it running as a resident process and it pushes a new menu
(preceded by a `~~~` line) only when something changes. That's what lets
the working-state spinner animate at 2 fps while `herdr api snapshot` is
still only polled every 5s (`SPIN_TICK` / `POLL` in the script) — and when
nothing changes, nothing is emitted at all. Clicks go through
`herdr workspace focus`, renumbering through `herdr workspace rename`.
Needs `jq`. Covers the default session only.

Setup: `brew install --cask swiftbar`, launch it once to pick a plugin
folder, copy the script there, make sure it's executable. Streamable
plugins are relaunched on refresh — after editing the copy, run
`open -g "swiftbar://refreshallplugins"` (a plain poll won't pick it up).

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

### Menu bar crowding

With two plugin icons (plus Tailscale, etc.) the menu bar fills up fast,
and macOS gives you no overflow UI: on a notched MacBook, icons that
don't fit silently vanish behind the notch — if a plugin "disappears" but
its script runs fine, it's crowding, not a bug. Cmd+drag reorders icons
(park the 🐑 and the lock next to the clock so they always fit) or
removes system ones; Control Center items can be hidden via System
Settings → Control Center ("Don't Show in Menu Bar" — they stay one
click away inside Control Center).

To fit more before that happens, shrink the per-icon padding (hidden
global defaults, stock is ~16px; 10 is comfortable, 6 is the practical
floor before icons get hard to click):

```bash
defaults -currentHost write -globalDomain NSStatusItemSpacing -int 10
defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 10
# revert: same commands with `delete` instead of `write -int 10`
```

Takes effect at the next log out/in. Gotcha observed on macOS 26: after
a logout, cfprefsd can wedge on the ByHost prefs file (it quarantines
its own plist, then reports the whole Apple Global Domain as
nonexistent while the file sits intact on disk; `defaults` writes fail
with "Could not write domain"). When that happens, edit the file
directly — `plutil -replace NSStatusItemSpacing -integer 10
~/Library/Preferences/ByHost/.GlobalPreferences.<hardware-UUID>.plist`
— strip the quarantine xattr, and let the next login's fresh cfprefsd
pick it up. Beyond spacing, a menu bar manager (Ice, free/open source,
or Bartender) adds a real overflow area.

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
