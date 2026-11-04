# Sourced from ~/.zshrc (setup.sh adds the line). Keep machine-specific stuff
# in ~/.zshrc; this file is the shared part and updates with `git pull`.

# Blinking block cursor (kept consistent with the vim cursor setting)
echo -e '\e[1 q'

# Reassert the themed cursor at every prompt (orange in light, pink in dark).
# Only matters in plain terminal tabs: Herdr drops OSC 12, and ghostty 1.4.0 no
# longer loses theme cursor colors on light/dark switches (#12708), so this is
# belt and braces for older ghostty / other terminals.
_theme_cursor() {
  if [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == Dark ]]; then
    printf '\e]12;#FFA9E7\a'
  else
    printf '\e]12;#F8BC82\a'
  fi
}
precmd_functions+=(_theme_cursor)

# Herdr: h [session] attaches to/creates a session named after the cwd
# herdr-palette attach: lets the palette (type @) switch sessions in place
h() {
  # plugin_root of a GitHub install (fixed across updates), else the linked
  # local checkout (herdr plugin link)
  local bin=(~/.config/herdr/plugins/github/binb1.palette-*/bin/herdr-palette(N[1])
             ~/Documents/projects/herdr-palette/bin/herdr-palette(N))
  bin=($bin[1])
  if (( $#bin )); then $bin attach "${1:-${PWD:t}}"
  elif print -u2 "h: herdr-palette not found, session switching off"
       [[ ${1:-${PWD:t}} == default ]]; then command herdr
  else command herdr --session "${1:-${PWD:t}}"
  fi
}
# Plain "herdr" / "herdr --session X" attach through the wrapper too, so
# every window can switch sessions; other subcommands pass through.
herdr() {
  if (( $# == 0 )); then h default
  elif [[ $1 == --session && $# == 2 ]]; then h "$2"
  elif [[ $1 == session && $2 == attach && $# == 3 ]]; then h "$3"
  else command herdr "$@"
  fi
}
