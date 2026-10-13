#!/usr/bin/env bash
# Claude Code status line: project  model·effort  wt name  ⎇ branch ↑1 ↓2 +1 ~3 ?1  ctx █░░░░ 9% (87k)  wk ███░░ 58%  rc
# Claude Code pipes the session JSON on stdin; see README.md for setup.

input=$(cat)
export LC_ALL=en_US.UTF-8

IFS=$'\x1f' read -r sid model effort dir ctx tokens week week_reset < <(
  jq -r '[
    (.session_id // ""),
    (.model.display_name // "?"),
    (.effort.level // ""),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.used_percentage // ""),
    (.context_window.current_usage // {} | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // "")
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

# rate_limits only arrives after a session's first API response, so a new session would show
# wk at 0%. The limit is account-wide: remember the last value until its window resets.
cache=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/weekly
if [[ -n $week ]]; then
  mkdir -p "${cache%/*}" && printf '%s %s\n' "$week" "$week_reset" >"$cache.$$" && mv "$cache.$$" "$cache"
elif read -r cached_week cached_reset 2>/dev/null <"$cache" && ((${cached_reset:-0} > $(date +%s))); then
  week=$cached_week
fi

bold=$'\e[1m' dim=$'\e[2m' reset=$'\e[0m' cyan=$'\e[36m' magenta=$'\e[35m' yellow=$'\e[33m' green=$'\e[32m' red=$'\e[31m'

# bar <percent> [note] → "███░░ 58%" (or "███░░ 58% (note)", note dimmed),
# green < 50, yellow < 80, red above
bar() {
  local pct=${1%.*} label=$2 width=5 filled color out=""
  ((pct < 0)) && pct=0
  ((pct > 100)) && pct=100
  filled=$(((pct * width + 50) / 100))
  if ((pct < 50)); then color=$'\e[32m'
  elif ((pct < 80)); then color=$'\e[33m'
  else color=$'\e[31m'; fi
  for ((i = 0; i < width; i++)); do
    ((i < filled)) && out+="█" || out+="░"
  done
  printf '%s%s%s %s' "$color" "$out" "$reset" "$pct%${label:+ ${dim}($label)${reset}}"
}

# Token count → "870", "87k", "1.2M"
human() {
  local n=${1:-0}
  if ((n < 1000)); then echo "$n"
  elif ((n < 1000000)); then echo "$(((n + 500) / 1000))k"
  else printf '%d.%dM\n' $((n / 1000000)) $(((n % 1000000 + 50000) / 100000 % 10)); fi
}

git=(git -C "${dir:-.}" --no-optional-locks)
branch=$("${git[@]}" branch --show-current 2>/dev/null)
gitdir=$("${git[@]}" rev-parse --absolute-git-dir 2>/dev/null)
[[ -n $gitdir ]] && common=$(cd "${dir:-.}" && cd "$(git rev-parse --git-common-dir)" && pwd -P)

# Project: the main repo's folder (same from any worktree), else the current folder
if [[ -n $common ]]; then project=$(basename "$(dirname "$common")")
else project=$(basename "${dir:-$PWD}"); fi

# Linked worktree: its git dir differs from the shared one
if [[ -n $gitdir && -n $common && $gitdir != "$common" ]]; then
  wt=$(basename "$("${git[@]}" rev-parse --show-toplevel)")
  [[ $branch == "$wt" ]] && branch=""
fi

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

counts=""
((ahead)) && counts+=" ${cyan}↑${ahead}${reset}"
((behind)) && counts+=" ${cyan}↓${behind}${reset}"
((staged)) && counts+=" ${green}+${staged}${reset}"
((modified)) && counts+=" ${yellow}~${modified}${reset}"
((untracked)) && counts+=" ${dim}?${untracked}${reset}"

bars="  ${dim}ctx${reset} $(bar "${ctx:-0}" "$(human "$tokens")")"
bars+="  ${dim}wk${reset} $(bar "${week:-0}")"

# Remote Control isn't in the status line JSON; while it's connected Claude Code records a
# bridgeSessionId in this process's ~/.claude/sessions/<pid>.json
bridge=$(jq -r --arg s "$sid" 'select(.sessionId == $s) | .bridgeSessionId // empty' \
  ~/.claude/sessions/*.json 2>/dev/null)
if [[ -n $sid && -n $bridge ]]; then rc="${green}rc${reset}"
else rc="${red}rc${reset}"; fi

# Visible width (escape codes stripped) and name clipping, in pure bash: the fitting loop
# below renders the line many times
shopt -s extglob
visible() { local s=${1//$'\e'\[*([0-9;])m/}; vis=${#s}; }
# clip <var> <text> <max> → var = text cut to max chars with a trailing "…" (0 = no limit)
clip() { if (($3 && ${#2} > $3)); then printf -v "$1" '%s…' "${2:0:$3-1}"; else printf -v "$1" '%s' "$2"; fi; }

# render <effort 0|1> <wt max> <branch max> <counts 0|1> → sets line (max: 0 = full, -1 = hide)
render() {
  line="${bold}${project}${reset}  ${cyan}${model}${reset}"
  (($1)) && [[ -n $effort ]] && line+="${dim}·${effort}${reset}"
  (($2 >= 0)) && [[ -n $wt ]] && clip w "$wt" "$2" && line+="  ${dim}wt${reset} ${yellow}${w}${reset}"
  (($3 >= 0)) && [[ -n $branch ]] && clip b "$branch" "$3" && line+="  ${magenta}⎇ ${b}${reset}"
  (($4)) && line+=$counts
  line+=$bars
}

# Usable width: COLUMNS (passed by Claude Code) minus the padding Claude Code draws around
# the status line, otherwise it cuts the end (rc) off with "…"
visible "$rc"; rcw=$vis
width=$((${COLUMNS:-0} - 4))
fits() { visible "$line"; ((width <= 0 || vis + 2 + rcw <= width)); }

# Too wide? Drop the least important parts until it fits: effort, then shorten
# worktree/branch names one char at a time (down to 8), then git counts, then the branch
# (worktree name shrinks again), then the worktree name. rc always stays.
longest=$((${#branch} > ${#wt} ? ${#branch} : ${#wt}))
render 1 0 0 1
fits || render 0 0 0 1
if ! fits; then
  for ((max = longest - 1; max >= 8; max--)); do render 0 $max $max 1; fits && break; done
fi
fits || render 0 8 8 0
if ! fits && [[ -n $wt ]]; then
  for ((max = ${#wt}; max >= 8; max--)); do render 0 $max -1 0; fits && break; done
fi
fits || render 0 -1 -1 0

# Right-align rc
visible "$line"
pad=$((width - vis - rcw))
((pad < 2)) && pad=2
printf '%s%*s%s\n' "$line" "$pad" "" "$rc"
