# Rex

[Rex](https://rex.superlogical.com) is the terminal multiplexer I'm moving the
Ghostty + Herdr setup to. Everything runs in a `Rex Server` process under
launchd; the app is only a window onto it, so quitting the app keeps every
session, shell and agent running.

## What's here

- `init.lua` — keybindings, a straight port of the Ghostty/Herdr ones:
  `alt+1..9` and `alt+shift+1..9` go to tab N, `shift+cmd+t` new tab,
  `ctrl+cmd+d` / `ctrl+shift+cmd+d` split right/down, `alt+shift+cmd+arrows`
  move between panes, `cmd+p` command palette.
- `themes.json` — the two custom themes, exported from Rex's preferences:
  `latte-custom` (light) and `mocha-custom` (dark), same colours as the Ghostty
  themes in `../ghostty/themes/`, including the orange `#F8BC82` / pink
  `#FFA9E7` cursors.
- `apply.sh` — installs all of it: copies `init.lua` (reloaded live with
  `rex config reload`), writes the themes and the preferences below with
  `defaults`.

## Preferences the script sets

Rex keeps everything except keybindings in `defaults` under
`com.superlogical.rex`:

| Key | Value | Why |
|---|---|---|
| `Workspace.lightThemeID` / `darkThemeID` | the two theme ids | pick the custom themes |
| `Workspace.interfaceStyle` | `useTheme` | chrome follows the theme |
| `Workspace.lightUsesExtendedThemePalette` / `dark…` | `true` | **required** for the theme's cursor and selection colours; without the dark one the cursor is white |
| `Workspace.terminalUsesDisplayP3` | `true` | matches Ghostty's `window-colorspace = display-p3` |
| `Workspace.terminalImproveTextContrast` | `false` | no automatic recolouring (Ghostty's `minimum-contrast` lesson: it eats pastel cursors) |
| `Workspace.terminalUseThemePalette` | `false` | programs keep their own colours |
| `Workspace.usesPaneGlass` | `false` | flat panes |
| `Workspace.inactivePaneFadeMode` | `none` | inactive panes keep full colour |

## Install

```sh
rex/apply.sh
```

Then quit and reopen Rex (Cmd+Q, relaunch). Theme and preference changes are
only read at launch; sessions are untouched because they live in the server.

To pull the current themes back into the repo after editing them in Rex's
Settings > Themes:

```sh
defaults export com.superlogical.rex - | python3 -c '
import plistlib,sys,json,io
p=plistlib.load(io.BytesIO(sys.stdin.buffer.read()))
json.dump(json.loads(p["Workspace.customThemes"]), open("rex/themes.json","w"), indent=2)'
```
