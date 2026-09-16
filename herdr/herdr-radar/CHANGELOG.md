# Changelog

## 1.3.4 — 2026-09-16

- **The Ghostty block no longer replaces your terminal font.** It wrote
  `font-family = "Herdr Agent Icons Max"` alongside the codepoint maps, and in
  Ghostty `font-family` is not "also load this" — it is the *primary* font. Ours
  holds icons and nothing else, so every ordinary character went looking in a
  font that cannot draw it and the terminal fell back to something you never
  chose: not the icons, every line of text. The `font-codepoint-map` lines
  redirect our two ranges whatever the primary font is, which is all this ever
  needed, so the `font-family` line is gone. `npm run check` now fails if
  anything we write into a terminal config claims that terminal's primary font.

  If you installed an earlier version, the line is still in your config. Re-run
  the plugin's install-font action — the managed block is replaced wholesale, so
  one run clears it. kitty was never affected; its `symbol_map` lines only ever
  mapped the ranges.

  Reported in [#4](https://github.com/hhdebb/herdr-radar/issues/4) by
  @adamflitney.

## 1.3.3 — 2026-09-16

- The README banner is rebuilt. Both screenshots are now the ground rather than
  objects sitting on it: faded down and masked at the edges, so no rectangle
  survives to read as a screenshot pasted onto the page. Light on the left, dark
  on the right, which is the theme story without a caption. All 23 vendor marks
  orbit the wordmark on three rings.

- The sidebar figure is both themes instead of one. It was a single portrait
  capture of the dark theme, about 830x1475 at the width the READMEs use —
  taller than the section it illustrates. Now the light capture is the base and
  the dark one is stacked on it, offset so it covers part of the light pane and
  leaves a strip of it showing; tops and heights match, so the same rows sit at
  the same height in both and can be read across.

- Every vendor mark is listed under that figure. The captures are one demo
  scene, and a scene has only as many panes as it has: that one came up a pane
  short of the roster, so `gpt` never got a row. The strip states the claim
  directly, from `assets/marks/`, so it stays right when a vendor is added.

## 1.3.2 — 2026-09-16

- A mirrored pane shows the remote's task title instead of a blank row. A
  mirror streamer runs no program of its own, so it has no terminal title at
  all — the title arrives in the `title` metadata slot, which the sidebar now
  reads when the terminal title says nothing. From
  [#2](https://github.com/hhdebb/herdr-radar/pull/2), by @larkinwc.

## 1.3.1 — 2026-09-16

- **The tab bar no longer polls itself into a pile-up.** The managed block asked
  Herdr to run the status command every 2 seconds with a 3-second timeout, so a
  tick that ran long was still running when the next one started. On Windows
  every tick is a fresh `cmd.exe` — Herdr's own config says so — and the overlap
  feeds itself: more overlap, slower machine, more timeouts, more overlap. On a
  24-core machine it ended at Herdr taking 12.5 cores, 35 console hosts, a
  hundred shells, and a desktop that would not move the mouse. Killing Herdr
  dropped the machine from saturated to 19%, and starting it brought the whole
  thing back within seconds.

  The interval is 6 seconds now and the timeout is derived from it, so the two
  cannot drift apart again; `npm run check` reads both back out of the generated
  block and fails if the interval is not the larger. The line the poll feeds is
  the current directory, which did not deserve a process three times a minute in
  the first place — Herdr's tab bar has no file source, so a command is the only
  way in, but it can be a quiet one.

  Anyone who installed an earlier version has the old numbers in their
  `config.toml`; re-running the plugin's configure step rewrites the block.

- The OSC7 hook no longer spends a process turning `/c/code/x` into `C:/code/x`.
  It runs before every prompt, and on Windows a subprocess is not free: measured
  on one machine, that single `cygpath` call cost about 150ms of kernel time per
  prompt. Parameter expansion gives the same answer — checked against `cygpath
  -m` on a deep path, on a bare drive root, and on another drive — and paths
  that are not Windows drives fall through untouched, which is what Linux and
  macOS need anyway. Both the bash and the zsh copies.

## 1.3.0 — 2026-09-14

- A mark with no colour of its own is drawn in ink — black on a light panel,
  white on a dark one — instead of inheriting Herdr's contextual default. That
  default is the sidebar's second-rank text grey, which left every brand that
  signs in black looking switched off beside the coloured ones. The sidebar
  block is rebuilt per appearance, so the two ends of the scale still follow
  the desktop.
- The working logo is no longer bold. The icon font ships one weight, so bold
  is synthesised by dilating the outline: the mark did not thicken, it grew,
  and a logo that changes size the moment a session stops working reads as a
  rendering fault. Working is still said three ways beside it — the spinner,
  the ring, and the title in the vendor's colour.
- Grok's mark is 15% larger than the shared fit. Two thin strokes running
  corner to corner fill a bounding box while the ink sits on a diagonal, so
  fitted like everything else it measures equal and reads a size smaller than
  the discs beside it.
- Antigravity and Kiro get their marks. Both SVGs were already in `tools/svg/`
  with nothing pointing at them; they are now glyphs `U+E1B2` and `U+E1B3` in
  the icon font, so the hand-mapped codepoint range in the README moves with
  them. Antigravity is keyed `agy` throughout, which is the id Herdr reports
  for it.
- A row whose terminal title says nothing but where the pane is now shows the
  agent's name instead. Codex never sets a title, and Antigravity and Kiro
  leave the shell's `<path>: <job>` form standing, so those rows read as the
  working directory the group header above them already named. Claude Code and
  grok write their own names and are untouched, as is any title an agent
  actually wrote.
- `dist/JetBrainsMonoHerdr-Regular.ttf` is rebuilt from the same JetBrains Mono
  2.304 base, carrying the same 29 icons as the icon font. It had been left at
  24 glyphs while the icon font grew, so a terminal that takes one font file and
  no fallback was missing the lifecycle marks as well as the newest vendors.
- Kiro wears the purple it publishes. Antigravity publishes a monochrome mark
  and so wears no colour at all, which is how every brand without a hue is
  treated here.
- The Spaces column colours every branded vendor, not just three. Which
  vendors get their own Spaces token was hardcoded in three separate places
  and had fallen behind the colour table, which is why Antigravity and Kiro
  were branded beside their titles and grey in Spaces. Gemini was in the same
  position and is fixed with them. All three places now read one roster.
- Fix the Spaces marks vanishing once a workspace carried enough vendors. A
  workspace's tokens went out in a single report, and Herdr rejects a patch
  over sixteen tokens whole rather than truncating it, without saying so. The
  workspace write is chunked now, like the pane writes already were.
- `grok` has an attribution row in `THIRD_PARTY_NOTICES.md`, which it never had.
- Amp, Devin and Qoder have marks. Herdr detects all three and the sidebar gave
  them a bare title and the fallback amber; they take U+E1B4–E1B6, leaving the
  two codepoints ahead of them for the pull request that draws Antigravity and
  Kiro. None of the three carries a colour: two sign in black, and Amp's red
  sits five degrees from the red that already means "waiting on you" here.
- Vendor colours are the vendors' own now, checked against the marks the
  companies publish: Kimi, DeepSeek and Qwen gain theirs, Cline and Kilo are
  carried at their own hue with a moved lightness (as published, one dies on a
  dark panel and the other on a light one), and the invented indigo and slate
  that Codex and Grok wore are gone. A brand that signs in black gets no
  colour at all — the cell leaves its `fg` unset, so the mark inherits the
  row's ink and follows the terminal's theme, which a static hex cannot.
- Only agent ids Herdr recognises are named under `rows_by_agent`. An id it
  does not know is not a warning: the config file fails to parse and every
  plugin falls back to defaults, keybindings included.
- The tab-bar `cwd` hook receives the pane it is answering for, like every
  other hook.
- Codex draws the OpenAI mark, the same one GPT has.
- The working spinner is eight-dot braille again. Six dots read thinner than
  the text beside them, and the icon font's twelve-spoke throbber only ever
  showed on a terminal carrying that font. A full braille cell is the mark
  that reads as motion from across the panel. The throbber's twelve glyphs
  left the font with it: an unused mark is one more thing to keep building.
- A working title wears its vendor's colour again, instead of one warm colour
  for all of them. With thirty rows the hue is what separates one running
  session from the next before any of them is read. This brings back a copy of
  the agent row per vendor (`rows_by_agent`): a value rule can colour a logo,
  whose value is the vendor's glyph, but not a title, whose value is prose.

Antigravity and Kiro — their marks, their names, their colours, and the
home-directory and title-fallback fixes that came with them — are
[#1](https://github.com/hhdebb/herdr-radar/pull/1), by @sizzlebop. It landed
squashed, so GitHub shows the pull request closed rather than merged; the
commit carries her authorship.

## 1.2.1

- Fix `agents_panel = herdr` reverting to the plugin a moment after it was
  saved. The daemon rewrites the managed blocks at startup when the sidebar
  block was written for a different logo variant, but the variant tag lives
  inside that block — and a panel handed back to Herdr has no block at all,
  which read as a variant that disagreed. The check now runs only while the
  block is there, because its absence is the whole record of that choice.
  Present since 1.1.0.

## 1.2.0

- The mark in front of a blocked row pulses instead of sitting still: the
  question mark and a quiet ring take turns in the same cell, about three
  quarters of a second each. Blocked is the one state that costs something to
  ignore, and it was the only event mark with no motion at all. Borrowed from
  Codex, which alternates `[ ! ]` with `[ . ]` in its terminal title while it
  waits for an answer.
- An agent's own blinking marker is dropped from the title — Codex writes
  `[ ! ]` / `[ . ]` into it while waiting. The row pulses its own mark for that
  state now, and two blinkers out of phase in one line is worse than either;
  the words after the bracket are kept. It also stops a title rewrite every
  second that said nothing new.
- The other halves of a split screen hang off the pane they were split from,
  the way a worktree's sessions hang off their checkout: one corner each, a
  grey one so the structure does not read louder than the row it holds. Panes
  sharing a tab also rank as one unit, so nothing unrelated lands between two
  halves of one screen.
- Fix the vendor colours 1.1.0 lost on every row below a group header. The rule
  matched the logo cell with `equals`, but an indented row's value carries a
  zero-width space and its indent in front of the glyph, so only a header's own
  row ever matched; it is `contains` now.
- A working row spins a twelve-spoke throbber from the icon font instead of a
  braille frame. Only the spoke widths change between frames, not the outer
  radius, so the shape turns without breathing. The plain-Unicode variant keeps
  the braille frames, and so does the merged JetBrains Mono build — it cannot be
  rebuilt here, it needs the upstream font as input.

## 1.1.0

Requires Herdr 0.9.0: the sidebar block now colours a logo by matching the
vendor's glyph, which older versions reject along with the rest of the file.

- Vendor colours come from per-value rules on one cell instead of a copy of the
  whole row per vendor. The block is 60% smaller, and Gemini joins the three
  vendors that had a colour of their own.
- A working row's title is bold, and the spinner in front of it is six-dot
  braille rather than eight — the two lower dots barely moved while the rest
  of the frame turned.
- Each frame sends only the tokens that changed, not all thirty-odd. A write
  that alters what is rendered costs Herdr about 100ms to answer, so the old
  full rewrite spent the frame budget queueing.
- The daemon no longer subscribes to `pane.updated`, which was mostly the echo
  of its own writes; agent status arrives on its own event now, and a slow
  heartbeat catches title changes.
- A daemon started by hand reads the plugin config again: without Herdr's
  injected config directory it silently ran on defaults.
- Refuse to write a sidebar row wider than Herdr's 16-token limit, which it
  answers by rejecting the whole config file.

## 1.0.4

- Drop a workspace name from the start of a title when the group header above already
  shows it; `trim_group_prefix` turns it off.

## 1.0.3

- The daemon applies the chosen order (default `active`) when it starts, not only from the
  server-startup hook; a first start by hand used to leave Herdr's own order until a restart.

## 1.0.2

- Refuse to install when `[theme.custom]` or a `[ui.sidebar.*]` table already exists outside
  the managed blocks; appending a second declaration broke Herdr's whole config.
- Appearance following records the original `[theme] name` / `auto_switch` on first write and
  `unconfigure` restores them.

## 1.0.1

- `unconfigure` now stops the daemon and clears every token before removing the blocks;
  `plugin uninstall` used to leave a detached daemon repainting a sidebar nobody rendered.
  `state-stop --purge` does the same clear on its own.
- Ghostty: the codepoint map is also written to `config.ghostty`, the file Ghostty reads
  alongside `config` on macOS.
- README: install from a checkout, boolean settings shown as `true`/`false`, the config
  file only exists after the first save, plugin log filtered by plugin, `herdr server stop`
  ends every pane.

## 1.0.0

First public release.

- Sidebar rows with vendor logos and lifecycle states; done and blocked marks are held
  until seen or answered; idle splits into fresh, idle and stale.
- Workspace headers, git worktree trees, Spaces column colouring.
- Two orders (`active`, `recent`) on top of Herdr's own, switchable per key.
- Tab-bar path, desktop light/dark following, settings popup.
- One-command install: managed config blocks, font and terminal codepoint map are set up
  on first start; `configure` / `install-font` actions to redo any step.
- Optional `render_hook` module for rewriting what is displayed.
