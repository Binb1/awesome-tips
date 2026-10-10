#!/usr/bin/env bash
# Claude Code status line: project  model·effort  wt name  branch ↑1 ↓2 +1 ~3 ?1  ctx █░░░░ 42%  wk ███░░ 58%
# Claude Code pipes the session JSON on stdin; see README.md for setup.

input=$(cat)

IFS=$'\x1f' read -r model effort dir ctx week < <(
  jq -r '[
    (.model.display_name // "?"),
    (.effort.level // ""),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // "")
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

bold=$'\e[1m' dim=$'\e[2m' reset=$'\e[0m' cyan=$'\e[36m' magenta=$'\e[35m' yellow=$'\e[33m' green=$'\e[32m'

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

git=(git -C "${dir:-.}" --no-optional-locks)
branch=$("${git[@]}" branch --show-current 2>/dev/null)
gitdir=$("${git[@]}" rev-parse --absolute-git-dir 2>/dev/null)
[[ -n $gitdir ]] && common=$(cd "${dir:-.}" && cd "$(git rev-parse --git-common-dir)" && pwd -P)

# Project: the main repo's folder (same from any worktree), else the current folder
if [[ -n $common ]]; then project=$(basename "$(dirname "$common")")
else project=$(basename "${dir:-$PWD}"); fi

line="${bold}${project}${reset}  ${cyan}${model}${reset}"
[[ -n $effort ]] && line+="${dim}·${effort}${reset}"

# Linked worktree: its git dir differs from the shared one
if [[ -n $gitdir && -n $common && $gitdir != "$common" ]]; then
  wt=$(basename "$("${git[@]}" rev-parse --show-toplevel)")
  line+="  ${dim}wt${reset} ${yellow}${wt}${reset}"
  [[ $branch == "$wt" ]] && branch=""
fi
[[ -n $branch ]] && line+="  ${magenta}${branch}${reset}"

# Ahead/behind the upstream + staged/modified/untracked counts, from one status call
ahead=0 behind=0 staged=0 modified=0 untracked=0
while read -r kind xy rest; do
  case $kind in
    "#") if [[ $xy == branch.ab ]]; then
           read -r a b _ <<<"$rest"
           ahead=${a#+} behind=${b#-}
         fi ;;
    1 | 2 | u)
      [[ ${xy:0:1} != . ]] && ((staged++))
      [[ ${xy:1:1} != . ]] && ((modified++)) ;;
    "?") ((untracked++)) ;;
  esac
done < <("${git[@]}" status --porcelain=v2 --branch 2>/dev/null)

((ahead)) && line+=" ${cyan}↑${ahead}${reset}"
((behind)) && line+=" ${cyan}↓${behind}${reset}"
((staged)) && line+=" ${green}+${staged}${reset}"
((modified)) && line+=" ${yellow}~${modified}${reset}"
((untracked)) && line+=" ${dim}?${untracked}${reset}"

line+="  ${dim}ctx${reset} $(bar "${ctx:-0}")"
line+="  ${dim}wk${reset} $(bar "${week:-0}")"

printf '%s\n' "$line"
