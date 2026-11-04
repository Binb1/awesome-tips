# Setting up a Mac from this repo (for a Claude Code agent)

Goal: reproduce Robin's terminal/editor setup. Everything is config in this
repo plus a handful of apps. Run the installer, then handle the short manual
list it prints. Re-running is safe.

## 0. Where to clone

`~/Documents/projects/awesome-tips`. The Claude Code statusline and the zsh
snippet are referenced at that path (no copies), so a `git pull` updates them.

## 1. Apps and CLIs

```sh
./setup.sh --brew        # brew bundle on mac-setup/Brewfile, then configs
```

`mac-setup/Brewfile` holds the casks (Ghostty, Zed, SwiftBar, ...), formulae
(herdr, jq, ...) and App Store apps via `mas` (sign in to the App Store first).
Rex is not on Homebrew: install it from https://rex.superlogical.com, launch it
once so its server and `rex` CLI exist.

## 2. What `setup.sh` does

| Piece | Installed to | Notes |
|---|---|---|
| Ghostty config + `latte-custom`/`mocha-custom` themes + icons | `~/.config/ghostty/` | validates with `ghostty +validate-config`; removes the in-app theme override if one exists |
| Herdr config | `~/.config/herdr/config.toml` | preserves the `# >>> herdr-ghostty-sidebar` block the sidebar plugin appends; reloads the server |
| Zed themes `Latte Custom` / `Mocha Custom` | `~/.config/zed/themes/` + `settings.json` theme keys | copies, never symlinks (Zed only hot-reloads on events inside that folder) |
| Rex keybindings, themes, preferences | `~/.config/rex/init.lua` + `defaults com.superlogical.rex` | via `rex/apply.sh`; app must be quit/reopened |
| Shell helpers + cursor hook | one `source` line appended to `~/.zshrc` | `zsh/awesome-tips.zsh`; `zsh/.zshrc` is the reference full file (oh-my-zsh, plugins) |
| Vim | `~/.vimrc` | |
| Claude Code statusline, agents, commands | `~/.claude/settings.json`, `~/.claude/agents`, `~/.claude/commands` | statusline points at the repo script |
| SwiftBar menu-bar plugins | SwiftBar's plugin folder | only if SwiftBar has been launched once |

## 3. Manual steps (the script lists the ones that apply)

1. **Herdr plugins**, from inside a Herdr pane (`herdr`):
   ```sh
   herdr plugin install Binb1/herdr-ghostty-sidebar --ref v0.1.2 --yes
   herdr plugin action invoke setup --plugin binb1.ghostty-sidebar
   herdr plugin action invoke claude-install --plugin binb1.ghostty-sidebar   # optional subagent rows
   herdr plugin install Binb1/herdr-palette --ref main --yes
   ```
   then quit and reopen Ghostty so it loads the sidebar logo font.
2. **Ghostty**: if it was already running, Cmd+Shift+, reloads the config.
3. **Rex**: Cmd+Q and reopen. Sessions survive, they live in the `Rex Server`
   launchd process, not the app.
4. **Zed**: if it was running when the themes were copied, pick
   `Latte Custom` once via `theme selector: toggle`, then it follows macOS.
5. **oh-my-zsh**: install it plus the plugins named in `zsh/.zshrc`
   (`git z zsh-autosuggestions zsh-syntax-highlighting`).

## 4. Verify

```sh
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config | grep -E '^(theme|cursor-color|minimum-contrast)'
#   theme = light:latte-custom,dark:mocha-custom ; cursor-color comes from the theme file ; minimum-contrast = 1.2
herdr status                       # server running, no "server_binary_stale"
ls ~/.config/zed/themes            # latte-custom.json mocha-custom.json
defaults read com.superlogical.rex Workspace.darkUsesExtendedThemePalette   # 1
zsh -ic 'whence -f _theme_cursor h >/dev/null && echo ok'
```

Visual check: light mode = grey `#DCDCE1` terminal, orange `#F8BC82` cursor;
dark mode = `#151517` terminal, pink `#FFA9E7` cursor. Same cursors in Rex and
Zed.

## 5. Gotchas worth knowing before changing anything

- Ghostty applies `minimum-contrast` to the cursor since 1.4.0. Orange on the
  light background is 1.23:1, so the value must stay at 1.2 or the cursor
  turns black.
- Ghostty's `cursor-color` lives in the theme files on purpose. A value in the
  main config would force one color in both appearances.
- Herdr forwards window titles to the host terminal but drops cursor-color
  escapes (OSC 12/112). Nothing inside Herdr can change the cursor color; the
  zsh hook only matters in plain tabs.
- Copying `herdr/config.toml` over the live file by hand drops the sidebar
  block; `setup.sh` re-appends it, or re-run the plugin's `setup` action.
- Rex ignores a theme's cursor/selection colors unless
  `Workspace.{light,dark}UsesExtendedThemePalette` are true.
