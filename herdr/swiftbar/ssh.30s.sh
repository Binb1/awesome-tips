#!/bin/bash
# <xbar.title>SSH Remote Login</xbar.title>
# <xbar.desc>Menu bar status for macOS Remote Login: on/off, who's connected (ssh + mosh), one-click toggle.</xbar.desc>
# <xbar.dependencies>none</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
#
# Companion to herdr.5s.sh — shows whether the Mac is reachable for the
# phone-SSH piloting flow (ssh/mosh in, run herdr). Toggling needs root, so the
# click handlers go through osascript's admin-password dialog. sshd is
# driven via launchctl, not `systemsetup -setremotelogin`: systemsetup
# demands Full Disk Access on top of root (macOS 13+) and fails from here.
# launchctl enable/disable is the same switch the Sharing pane flips.
#
# Mosh: bootstraps over ssh then lives on its own UDP channel, so Remote
# Login stays the master switch for NEW connections — but an established
# mosh session survives sshd being turned off. mosh-server processes are
# counted separately so the icon can't claim "unreachable" while a phone
# is still attached.

# Click handlers: SwiftBar re-runs this script as "$0 on|off|copy|copymosh"
case "$1" in
  on)
    ERR="$(/usr/bin/osascript -e 'do shell script "launchctl enable system/com.openssh.sshd && launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist" with administrator privileges' 2>&1 >/dev/null)" \
      || /usr/bin/osascript -e "display notification \"$ERR\" with title \"SSH toggle failed\"" >/dev/null 2>&1
    exit 0 ;;
  off)
    ERR="$(/usr/bin/osascript -e 'do shell script "launchctl bootout system/com.openssh.sshd; launchctl disable system/com.openssh.sshd" with administrator privileges' 2>&1 >/dev/null)" \
      || /usr/bin/osascript -e "display notification \"$ERR\" with title \"SSH toggle failed\"" >/dev/null 2>&1
    exit 0 ;;
  copy)
    printf 'ssh %s@%s' "$USER" "$2" | /usr/bin/pbcopy
    exit 0 ;;
  copymosh)
    printf 'mosh %s@%s' "$USER" "$2" | /usr/bin/pbcopy
    exit 0 ;;
  cleanmosh)
    # Kill every detached mosh-server except the youngest (smallest etime).
    # Safe: panes live in the Herdr server; a phone just reconnects fresh.
    /bin/ps -axo pid=,ppid=,etime=,comm= | /usr/bin/awk '
      $2 == 1 && $4 ~ /mosh-server$/ {
        e = $3; d = 0
        if (e ~ /-/) { split(e, dd, "-"); d = dd[1]; e = dd[2] }
        n = split(e, t, ":")
        s = (n == 3) ? ((d*24 + t[1])*3600 + t[2]*60 + t[3]) : (d*86400 + t[1]*60 + t[2])
        print s, $1
      }' | /usr/bin/sort -n | /usr/bin/awk 'NR > 1 {print $2}' | /usr/bin/xargs kill 2>/dev/null
    exit 0 ;;
esac

IP="$(/usr/sbin/ipconfig getifaddr en0 2>/dev/null || /usr/sbin/ipconfig getifaddr en1 2>/dev/null)"

# Tailscale: prefer the CLI (GUI app bundle or brew), fall back to spotting
# the CGNAT 100.x address on a utun interface (works whichever variant is
# installed, and even if the CLI is missing).
TS_BIN=""
for c in "/Applications/Tailscale.app/Contents/MacOS/Tailscale" \
         "$HOME/Applications/Tailscale.app/Contents/MacOS/Tailscale" \
         "/opt/homebrew/bin/tailscale" "/usr/local/bin/tailscale"; do
  [ -x "$c" ] && { TS_BIN="$c"; break; }
done
# The GUI app's CLI can hang if the daemon/VPN extension isn't running
# (e.g. freshly installed, never signed in) — hard 3s cap via perl alarm
# (macOS ships no `timeout`).
TS_IP=""
[ -n "$TS_BIN" ] && TS_IP="$(/usr/bin/perl -e 'alarm 3; exec @ARGV' "$TS_BIN" ip -4 2>/dev/null | /usr/bin/head -1)"
[ -z "$TS_IP" ] && TS_IP="$(/sbin/ifconfig 2>/dev/null | /usr/bin/awk '/^utun/{u=1; next} /^[a-z]/{u=0} u && $1 == "inet" && $2 ~ /^100\./ {print $2; exit}')"

# sshd only listens when Remote Login is on — no root needed to check.
if /usr/bin/nc -z -G 2 localhost 22 >/dev/null 2>&1; then SSH_ON=1; else SSH_ON=0; fi

# Remote sessions show up in `who` with the source in parens. Mosh entries
# read "(mosh [pid])" instead of a hostname — split those out. The mosh
# count is mosh-server processes reparented to PID 1: a real session runs
# detached (ppid 1, no tty), exactly one such process per session. Counting
# by tty doesn't work — real sessions hold no controlling tty — and a raw
# pgrep double-counts the supervisor+child pair of a locally spawned server.
WHO="$(/usr/bin/who | /usr/bin/awk '/\(/ { match($0, /\(.*\)/); print $1"\t"substr($0, RSTART+1, RLENGTH-2) }' | /usr/bin/sort -u)"
SSH_CONNS="$(printf '%s\n' "$WHO" | /usr/bin/grep -v $'\t''mosh' | /usr/bin/grep .)"
NSSH=0; [ -n "$SSH_CONNS" ] && NSSH="$(printf '%s\n' "$SSH_CONNS" | /usr/bin/grep -c .)"
MOSH_PIDS="$(/bin/ps -axo pid,ppid,comm | /usr/bin/awk '$2 == 1 && $3 ~ /mosh-server$/ {print $1}')"
NMOSH=0; [ -n "$MOSH_PIDS" ] && NMOSH="$(printf '%s\n' "$MOSH_PIDS" | /usr/bin/grep -c .)"

# Mosh is connectionless: a suspended phone and a dead client look the same,
# so "connected" is really "traffic since the last poll". Sample per-process
# byte counters (nettop) and diff them against the previous poll's state.
STATE="$HOME/.cache/swiftbar-ssh30s.mosh"
NMOSH_ACT=0; MOSH_ROWS=""
if [ "$NMOSH" -gt 0 ]; then
  /bin/mkdir -p "$HOME/.cache"
  PFLAGS=""; for p in $MOSH_PIDS; do PFLAGS="$PFLAGS -p $p"; done
  NOW="$(/usr/bin/nettop -x -L 1 -P $PFLAGS -J bytes_in,bytes_out 2>/dev/null \
    | /usr/bin/awk -F, '$1 ~ /^mosh-server\./ {split($1, a, "."); print a[2], $2 + $3}')"
  for p in $MOSH_PIDS; do
    up="$(/bin/ps -o etime= -p "$p" | /usr/bin/tr -d ' ')"
    new="$(printf '%s\n' "$NOW" | /usr/bin/awk -v p="$p" '$1 == p {print $2}')"
    old="$(/usr/bin/awk -v p="$p" '$1 == p {print $2}' "$STATE" 2>/dev/null)"
    if [ -n "$new" ] && [ "$new" != "$old" ]; then
      NMOSH_ACT=$((NMOSH_ACT + 1))
      MOSH_ROWS="$MOSH_ROWS
$USER via mosh — active (up $up) | sfimage=iphone.radiowaves.left.and.right sfcolor=#5BB974 sfsize=12 size=13"
    else
      MOSH_ROWS="$MOSH_ROWS
$USER via mosh — quiet (up $up) | sfimage=iphone.slash sfcolor=#98989D sfsize=12 size=13"
    fi
  done
  printf '%s\n' "$NOW" > "$STATE"
else
  /bin/rm -f "$STATE" 2>/dev/null
fi
NCONN=$((NSSH + NMOSH))
NACT=$((NSSH + NMOSH_ACT))

# Same laptop glyph in every state — open lock = reachable, closed = off.
# Green count = sessions with traffic since last poll; gray count = only
# quiet sessions (suspended phone or stale server — mosh can't tell).
# Closed lock + count = sshd off but mosh sessions still alive.
if [ "$SSH_ON" = 1 ]; then
  if [ "$NACT" -gt 0 ]; then
    echo "$NACT | sfimage=lock.open.laptopcomputer sfcolor=#5BB974 sfsize=13 size=12"
  elif [ "$NCONN" -gt 0 ]; then
    echo "$NCONN | sfimage=lock.open.laptopcomputer sfcolor=#98989D sfsize=13 size=12"
  else
    echo "| sfimage=lock.open.laptopcomputer sfcolor=#98989D sfsize=13"
  fi
elif [ "$NMOSH" -gt 0 ]; then
  echo "$NMOSH | sfimage=lock.laptopcomputer sfcolor=#E8A33D sfsize=13 size=12"
else
  echo "| sfimage=lock.laptopcomputer sfcolor=#98989D sfsize=13"
fi

echo "---"

print_conns() {
  if [ -n "$SSH_CONNS" ]; then
    while IFS=$'\t' read -r user host; do
      echo "$user from $host | sfimage=iphone sfcolor=#E8A33D sfsize=12 size=13"
    done <<<"$SSH_CONNS"
  fi
  [ -n "$MOSH_ROWS" ] && printf '%s\n' "$MOSH_ROWS" | /usr/bin/grep .
  if [ "$NMOSH" -gt 1 ]; then
    echo "Kill all but newest mosh session | sfimage=trash sfcolor=#E35D6A sfsize=12 size=13 bash=\"$0\" param1=cleanmosh terminal=false refresh=true"
  fi
}

# Status block at the top: Remote Login, Tailscale, connection count.
print_tailscale() {
  if [ -n "$TS_IP" ]; then
    echo "Tailscale — $TS_IP | sfimage=point.3.connected.trianglepath.dotted sfcolor=#5BB974 sfsize=12 size=13"
  elif [ -n "$TS_BIN" ]; then
    echo "Tailscale off | sfimage=point.3.connected.trianglepath.dotted sfcolor=#98989D sfsize=12 size=13"
  else
    echo "Tailscale not installed | sfimage=point.3.connected.trianglepath.dotted sfcolor=#98989D sfsize=12 size=13"
  fi
}

if [ "$SSH_ON" = 1 ]; then
  echo "Remote Login on — ${IP:-no network} | sfimage=checkmark.shield.fill sfcolor=#5BB974 sfsize=12 size=13"
  print_tailscale
  if [ "$NCONN" -gt 0 ]; then
    NQUIET=$((NMOSH - NMOSH_ACT))
    LBL="Active connections: $NACT"; [ "$NQUIET" -gt 0 ] && LBL="$LBL (+$NQUIET quiet)"
    if [ "$NACT" -gt 0 ]; then
      echo "$LBL | sfimage=person.2.fill sfcolor=#E8A33D sfsize=12 size=13"
    else
      echo "$LBL | sfimage=person.2 sfcolor=#98989D sfsize=12 size=13"
    fi
    print_conns
  else
    echo "Active connections: 0 | color=gray size=13"
  fi
  if [ -n "$TS_IP" ]; then
    echo "Copy: mosh $USER@$TS_IP | sfimage=doc.on.doc sfsize=12 size=13 bash=\"$0\" param1=copymosh param2=$TS_IP terminal=false"
    echo "Copy: ssh $USER@$TS_IP | sfimage=doc.on.doc sfsize=12 size=13 bash=\"$0\" param1=copy param2=$TS_IP terminal=false"
  fi
  if [ -n "$IP" ]; then
    echo "Copy: mosh $USER@$IP (LAN) | sfimage=doc.on.doc sfsize=12 size=13 bash=\"$0\" param1=copymosh param2=$IP terminal=false"
    echo "Copy: ssh $USER@$IP (LAN) | sfimage=doc.on.doc sfsize=12 size=13 bash=\"$0\" param1=copy param2=$IP terminal=false"
  fi
  echo "Turn SSH off | sfimage=lock.slash sfcolor=#E35D6A sfsize=12 size=13 bash=\"$0\" param1=off terminal=false refresh=true"
else
  echo "Remote Login off | sfimage=shield.slash sfcolor=#98989D sfsize=12 size=13"
  print_tailscale
  if [ "$NMOSH" -gt 0 ]; then
    echo "$NMOSH mosh session(s) still connected | sfimage=exclamationmark.triangle sfcolor=#E8A33D sfsize=12 size=13"
    print_conns
  fi
  echo "Turn SSH on | sfimage=lock.open sfcolor=#5BB974 sfsize=12 size=13 bash=\"$0\" param1=on terminal=false refresh=true"
fi
