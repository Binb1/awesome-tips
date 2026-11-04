# Zed

## Themes

`themes/latte-custom.json` — light theme built entirely from the Ghostty
`latte-custom` palette (`../ghostty/themes/latte-custom`) and the Herdr chrome
overrides (`../herdr/config.toml`), laid out like VS Code Light+ but
pink/blue only: semibold pink keywords, blue strings and numbers, azure
functions, magenta keys/properties/decorators, bright-blue types and tags, green
comments, plain text for variables and punctuation. Orange is
reserved for the cursor, git marks and diagnostics; green also marks added files. Chrome:

- editor `#F4F4F7`, panels `#EAEAEE`, status/title bar `#E3E3E8`; the Ghostty
  grey `#DCDCE1` is the hover tone, foreground `#222432`
- cursor pastel orange `#F8BC82`; search matches use the same orange
- selection, current line and selected sidebar rows pastel blue `#b9cdf2`
  (Herdr's `active_row_bg`)
- accent (links, focused borders, info) azure `#2E9BE0` (Herdr's `teal`)
- terminal ANSI colours = the Ghostty palette
- UI greys = Ghostty palette 0/7/8/15 and Herdr's `overlay0/1`

`themes/mocha-custom.json` — the dark counterpart, same role layout, built
from the Ghostty `mocha-custom` palette and the Herdr dark overrides: near-black
editor `#151517`, foreground `#EFF1F8`, pink `#FFA9E7` cursor, `#585b70` selection,
`#363b52` selected rows (Herdr's dark `active_row_bg`), azure accent, terminal
ANSI = the Ghostty mocha palette. Yellow takes orange's role for search matches
and modified files.

Install: copy both into Zed's theme dir (a symlink does not work: Zed only
reloads on file events inside `~/.config/zed/themes/`), then pick it in
`settings.json`.

```sh
cp zed/themes/*.json ~/.config/zed/themes/
```

```json
"theme": { "mode": "system", "light": "Latte Custom", "dark": "Mocha Custom" }
```

Zed watches `~/.config/zed/themes/`, so re-copying after an edit applies it live.
