#!/bin/bash
# <xbar.title>SSH Remote Login</xbar.title>
# <xbar.desc>Menu bar status for macOS Remote Login: on/off, who's connected, one-click toggle.</xbar.desc>
# <xbar.dependencies>none</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
#
# Companion to herdr.5s.sh — shows whether the Mac is reachable for the
# phone-SSH piloting flow (ssh in, run herdr). Toggling needs root, so the
# click handlers go through osascript's admin-password dialog. sshd is
# driven via launchctl, not `systemsetup -setremotelogin`: systemsetup
# demands Full Disk Access on top of root (macOS 13+) and fails from here.
# launchctl enable/disable is the same switch the Sharing pane flips.

# Click handlers: SwiftBar re-runs this script as "$0 on|off|copy"
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
esac

IP="$(/usr/sbin/ipconfig getifaddr en0 2>/dev/null || /usr/sbin/ipconfig getifaddr en1 2>/dev/null)"

# sshd only listens when Remote Login is on — no root needed to check.
if /usr/bin/nc -z -G 2 localhost 22 >/dev/null 2>&1; then SSH_ON=1; else SSH_ON=0; fi

# Remote sessions show up in `who` with the source host in parens.
CONNS="$(/usr/bin/who | /usr/bin/awk '/\(/ {gsub(/[()]/,"",$NF); print $1"\t"$NF}' | /usr/bin/sort -u)"
NCONN=0; [ -n "$CONNS" ] && NCONN="$(printf '%s\n' "$CONNS" | /usr/bin/grep -c .)"

# Same laptop glyph in every state — open lock = reachable, closed = off.
if [ "$SSH_ON" = 1 ]; then
  if [ "$NCONN" -gt 0 ]; then
    echo "$NCONN | sfimage=lock.open.laptopcomputer sfcolor=#5BB974 sfsize=13 size=12"
  else
    echo "| sfimage=lock.open.laptopcomputer sfcolor=#98989D sfsize=13"
  fi
else
  echo "| sfimage=lock.laptopcomputer sfcolor=#98989D sfsize=13"
fi

echo "---"

if [ "$SSH_ON" = 1 ]; then
  echo "Remote Login on — ${IP:-no network} | sfimage=checkmark.shield.fill sfcolor=#5BB974 sfsize=12 size=13"
  if [ "$NCONN" -gt 0 ]; then
    while IFS=$'\t' read -r user host; do
      echo "$user from $host | sfimage=iphone sfcolor=#E8A33D sfsize=12 size=13"
    done <<<"$CONNS"
  else
    echo "No active connections | color=gray size=13"
  fi
  [ -n "$IP" ] && echo "Copy: ssh $USER@$IP | sfimage=doc.on.doc sfsize=12 size=13 bash=\"$0\" param1=copy param2=$IP terminal=false"
  echo "Turn SSH off | sfimage=lock.slash sfcolor=#E35D6A sfsize=12 size=13 bash=\"$0\" param1=off terminal=false refresh=true"
else
  echo "Remote Login off | sfimage=shield.slash sfcolor=#98989D sfsize=12 size=13"
  echo "Turn SSH on | sfimage=lock.open sfcolor=#5BB974 sfsize=12 size=13 bash=\"$0\" param1=on terminal=false refresh=true"
fi
