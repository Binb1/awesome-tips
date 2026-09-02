# SwiftBar mini guide

Everything we learned building `herdr.5s.sh` (the Herdr agent-status menu
bar item), distilled. SwiftBar turns any script's stdout into a native
macOS menu bar item — no Xcode, no signing, edits apply on the next
refresh.

## The contract

One executable file in the plugin folder. The filename sets the schedule:
`herdr.5s.sh` runs every 5 seconds (`2s`, `1m`, `1h`... — rename to
retune). Stdout becomes the UI:

```
🐑 2            <- line 1: the menu bar item itself
---             <- separator
row one         <- everything after: the dropdown
row two | color=gray
```

Everything after a `|` on a line is parameters. The ones we used:

| Param | Effect |
|---|---|
| `sfimage=circle.fill` | SF Symbol icon on a row (native look; browse names in Apple's free "SF Symbols" app) |
| `sfcolor=#E8A33D` | tint for that symbol (our status dots: amber/red/green/gray) |
| `sfsize=12` / `size=13` | symbol / text size |
| `color=gray` | row text color |
| `bash=... param1=... param2=...` | run a command on click |
| `terminal=false` | don't open Terminal for the click command |
| `refresh=true` | re-run the plugin right after the click |

In the **title line** (line 1), SF Symbols use `:name:` syntax instead
(`:xmark.circle:`) and can mix with text and emoji. Template-rendered
symbols match the other monochrome menu extras; an emoji (our 🐑) keeps
its colors — pick per taste.

## Metadata comments

Header comments configure SwiftBar per plugin:

```bash
# <xbar.title>Herdr Agents</xbar.title>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
```

The `hide*` flags strip the footer noise ("About", "Last updated",
the SwiftBar row) for a clean dropdown. Note: with `hideSwiftBar`,
reaching SwiftBar's own preferences means ⌥-clicking the menu bar item.

## Click handlers: the self-invoke pattern

A clickable row points `bash=` back at the plugin script itself with a
verb as `param1`; the script branches on `$1` before doing its normal
render:

```bash
if [ "$1" = "focus" ]; then
  "$HERDR" workspace focus "$2" >/dev/null 2>&1
  /usr/bin/osascript -e 'tell application "Ghostty" to activate'
  exit 0
fi
```

One file stays the whole feature. Quote the path in the row
(`bash="\($self)"`) — plugin folders can contain spaces.

## Polls can have side effects

A plugin is just a script on a timer, so it can *maintain* state, not only
display it. Ours renumbers Herdr workspace labels ("3. awesome-tips") on
every poll before rendering — a 5-second-latency reconciliation loop for
free. Keep such passes idempotent (only act on mismatches).

## Workflow

```bash
brew install --cask swiftbar        # first launch asks for a plugin folder
cp herdr.5s.sh <plugin-folder>/ && chmod +x <plugin-folder>/herdr.5s.sh
open -g "swiftbar://refreshallplugins"   # force re-run after edits
```

- **Debug by running the script in a terminal** — the printed text is
  exactly what SwiftBar renders. No output/nonzero exit shows as a broken
  plugin.
- **Sanitize dynamic text**: a `|` inside interpolated content (pane
  titles!) is parsed as a parameter separator — strip or replace it.
- **Handle the down state**: if the backing service is gone, print a
  fallback title + row and `exit 0` instead of dying.
- **Launch at login**: the checkbox lives in SwiftBar's preferences, or
  register it directly:
  `osascript -e 'tell application "System Events" to make new login item at end with properties {path:"/Applications/SwiftBar.app", hidden:true}'`
