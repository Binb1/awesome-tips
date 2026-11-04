-- Rex config, migrated from Herdr and Ghostty.

-- Herdr: ~/.config/herdr/config.toml:47 switch_tab = "alt+1..9"
rex.bind("alt+1", "client.tab.goto", { index = 1 })
rex.bind("alt+2", "client.tab.goto", { index = 2 })
rex.bind("alt+3", "client.tab.goto", { index = 3 })
rex.bind("alt+4", "client.tab.goto", { index = 4 })
rex.bind("alt+5", "client.tab.goto", { index = 5 })
rex.bind("alt+6", "client.tab.goto", { index = 6 })
rex.bind("alt+7", "client.tab.goto", { index = 7 })
rex.bind("alt+8", "client.tab.goto", { index = 8 })
rex.bind("alt+9", "client.tab.goto", { index = 9 })

-- Ghostty: ~/.config/ghostty/config:109-115 (new tab, splits, split focus)
rex.bind("shift+cmd+t", "client.tab.new")
rex.bind("ctrl+cmd+d", "pane.split", { direction = "right" })
rex.bind("ctrl+shift+cmd+d", "pane.split", { direction = "down" })
rex.bind("alt+shift+cmd+left", "pane.focus", { direction = "left" })
rex.bind("alt+shift+cmd+right", "pane.focus", { direction = "right" })
rex.bind("alt+shift+cmd+up", "pane.focus", { direction = "up" })
rex.bind("alt+shift+cmd+down", "pane.focus", { direction = "down" })

-- Ghostty: ~/.config/ghostty/config:138-146 (goto_tab:1..9)
rex.bind("alt+shift+1", "client.tab.goto", { index = 1 })
rex.bind("alt+shift+2", "client.tab.goto", { index = 2 })
rex.bind("alt+shift+3", "client.tab.goto", { index = 3 })
rex.bind("alt+shift+4", "client.tab.goto", { index = 4 })
rex.bind("alt+shift+5", "client.tab.goto", { index = 5 })
rex.bind("alt+shift+6", "client.tab.goto", { index = 6 })
rex.bind("alt+shift+7", "client.tab.goto", { index = 7 })
rex.bind("alt+shift+8", "client.tab.goto", { index = 8 })
rex.bind("alt+shift+9", "client.tab.goto", { index = 9 })

-- Herdr: ~/.config/herdr/config.toml:77 cmd+p opened the binb1.palette command palette
rex.bind("cmd+p", "client.palette.toggle")
