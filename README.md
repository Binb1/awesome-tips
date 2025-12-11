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
