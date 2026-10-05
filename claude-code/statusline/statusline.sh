#!/usr/bin/env bash
# Claude Code status line: model·effort  branch  ctx █░░░░ 42%  5h ██░░░ 31%  wk ███░░ 58%
# Claude Code pipes the session JSON on stdin; see README.md for setup.

input=$(cat)

IFS=$'\x1f' read -r model effort dir ctx five week < <(
  jq -r '[
    (.model.display_name // "?"),
    (.effort.level // ""),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // "")
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

dim=$'\e[2m' reset=$'\e[0m' cyan=$'\e[36m' magenta=$'\e[35m'

# bar <percent> → "███░░ 58%", green < 50, yellow < 80, red above
bar() {
  local pct=${1%.*} width=5 filled color out=""
  ((pct < 0)) && pct=0
  ((pct > 100)) && pct=100
  filled=$(((pct * width + 50) / 100))
  if ((pct < 50)); then color=$'\e[32m'
  elif ((pct < 80)); then color=$'\e[33m'
  else color=$'\e[31m'; fi
  for ((i = 0; i < width; i++)); do
    ((i < filled)) && out+="█" || out+="░"
  done
  printf '%s%s%s %d%%' "$color" "$out" "$reset" "$pct"
}

line="${cyan}${model}${reset}"
[[ -n $effort ]] && line+="${dim}·${effort}${reset}"

branch=$(git -C "${dir:-.}" --no-optional-locks branch --show-current 2>/dev/null)
[[ -n $branch ]] && line+="  ${magenta}${branch}${reset}"

[[ -n $ctx ]] && line+="  ${dim}ctx${reset} $(bar "$ctx")"
[[ -n $five ]] && line+="  ${dim}5h${reset} $(bar "$five")"
[[ -n $week ]] && line+="  ${dim}wk${reset} $(bar "$week")"

printf '%s\n' "$line"
