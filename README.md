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

**On the go setup**<br />
Claude Code on VPS + Telegram bot flow to message me when PRs are opened. [demo](https://thebuildupdev.substack.com/p/claude-code-from-anywhere-with-your)<br />

# Terminal &amp; editor setup

My terminal stack follows the macOS system appearance — everything flips between light and dark together.

**Ghostty** (`ghostty/`)<br />
`config` sets `theme = light:light-theme,dark:dark-theme`, and the two palettes live in `ghostty/themes/`: Catppuccin Latte for light, a custom near-black Catppuccin Mocha for dark. App icons for each mode are in `ghostty/icons/`.<br />

**Vim** (`vim/vimrc`)<br />
Auto-switches `background`/`colorscheme` based on `defaults read -g AppleInterfaceStyle`, plus QoL defaults (line numbers, smartcase search, 2-space indent, blinking block cursor, mouse on).<br />

**Zsh** (`zsh/.zshrc`)<br />
Oh My Zsh with the `ys` theme and the `git z zsh-autosuggestions zsh-syntax-highlighting` plugins, a 50k-line shared history, and a blinking block cursor to match vim. Plugins are loaded once via the OMZ array (syntax-highlighting last) — no manual `source` duplication.<br />

# Claude code<br />

Claude code is my go to AI tool to help me code.<br />
It's very important to setup it well to obtain good results.<br />
I'm using subagents in Claude code, you can find a folder in all the subagents I use on my projects in the claude-code-agents folder/<br />

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
