# awesome-tips

All the cool tips &amp; tech stuff I use, in one page !

# Coding setup

## Current go-to stack

**Front**<br />
Vite + React + Typescript<br />
NextJS when deploying on vercel<br />

**Back**<br />
Python (typed) + Fast API<br />
Langgraph + langchain for agentic framework<br />
Langfuse for agent tracing<br />

**Tools**<br />
Claude Code with subagents<br />
Cursor for manual code edition<br /><br />

**Terminal**<br />
Ghostty + Herdr (terminal multiplexer for AI agents), with custom light/dark themes that follow macOS appearance and a SwiftBar menu-bar widget for live agent status. Currently moving to Rex, which replaces both.<br />
Full setup guide in [herdr/](herdr/) — configs: [herdr/config.toml](herdr/config.toml), [ghostty/config](ghostty/config), themes in [ghostty/themes/](ghostty/themes/); Rex port in [rex/](rex/)<br />

**On the go setup**<br />
Claude Code on VPS + Telegram bot flow to message me when PRs are opened. [demo](https://thebuildupdev.substack.com/p/claude-code-from-anywhere-with-your)<br />

# Mac setup

Fresh machine: `./setup.sh --brew` installs every config in this repo (idempotent), and [SETUP.md](SETUP.md) is the step-by-step written for a Claude Code agent, manual steps and verification included.<br />

All the apps and CLI tools I install on a fresh Mac live in [mac-setup/Brewfile](mac-setup/Brewfile): Homebrew casks, App Store apps (via `mas`), and a few manual installs noted at the bottom.<br />
`brew bundle --file=mac-setup/Brewfile` (sign in to the App Store first)<br />

# Terminal &amp; editor setup

My terminal stack follows the macOS system appearance — everything flips between light and dark together.

**Ghostty** (`ghostty/`)<br />
`config` sets `theme = light:latte-custom,dark:mocha-custom`, and the two palettes live in `ghostty/themes/`: a vivid grey-background Catppuccin Latte variant for light, a custom near-black Catppuccin Mocha for dark. Per-mode app icons are in `ghostty/icons/` (dark → dracula, light → ayu-light), switched live via a `current.icns` symlink maintained by the SwiftBar plugin.<br />

**Rex** (`rex/`)<br />
The same setup ported to [Rex](https://rex.superlogical.com): `init.lua` carries the Ghostty/Herdr keybindings, `themes.json` the `latte-custom` / `mocha-custom` themes (orange and pink cursors included), and `apply.sh` installs both plus the `defaults` that make Rex honour them (extended theme palette on, Display P3 on, text-contrast and theme-palette forcing off). Run `rex/apply.sh`, then quit and reopen Rex; sessions survive because they live in the Rex server. Details in [rex/README.md](rex/README.md).<br />

**Zed** (`zed/`)<br />
`themes/latte-custom.json` is a light Zed theme: the Ghostty `latte-custom` palette as syntax colours (pink keywords, blue strings and numbers, azure functions, magenta keys, bright-blue types, green comments) on an off-white editor, plus Herdr chrome colours (orange cursor, azure accent, pastel-blue selection and rows). `themes/mocha-custom.json` is the dark counterpart from the `mocha-custom` palette (near-black editor, pink `#FFA9E7` cursor, slate selection). Copy both into `~/.config/zed/themes/` and set `"light": "Latte Custom", "dark": "Mocha Custom"`; with `"mode": "system"` Zed flips with macOS like the rest of the stack.<br />

**Vim** (`vim/vimrc`)<br />
Auto-switches `background`/`colorscheme` based on `defaults read -g AppleInterfaceStyle`, plus QoL defaults (line numbers, smartcase search, 2-space indent, blinking block cursor, mouse on).<br />

**Zsh** (`zsh/.zshrc`)<br />
Oh My Zsh with the `ys` theme and the `git z zsh-autosuggestions zsh-syntax-highlighting` plugins, a 50k-line shared history, and a blinking block cursor to match vim. Plugins are loaded once via the OMZ array (syntax-highlighting last) — no manual `source` duplication.<br />

# Claude code<br />

Claude code is my go to AI tool to help me code.<br />
It's very important to setup it well to obtain good results.<br />
I'm using subagents in Claude code — the agents, commands, and skills I use on my projects are in the [claude-code/](claude-code/) folder.<br />
Custom status line (project, model, worktree, branch + git status, context usage and weekly limit as full-block bars, Remote Control on/off): [claude-code/statusline/](claude-code/statusline/)<br />

## Useful ressources

https://github.com/wshobson/agents
https://www.buildwithclaude.com/

### Whobson plugins

**Step 1**
`/plugin marketplace add wshobson/agents`

**List of plugins**
Dev
/plugin install python-development
/plugin install javascript-typescript

Process
/plugin install git-pr-workflows
/plugin install documentation-generation

Marketing
/plugin install seo-technical-optimization
/plugin install content-marketing

Payment
/plugin install payment-processing

AI
https://github.com/wshobson/agents/blob/main/plugins/llm-application-dev/agents/ai-engineer.md
