#!/bin/bash
#/ Usage: bin/install-sh.sh [--debug]
#/ Install development dependencies on macOS.
set -e

[[ "$1" = "--debug" || -o xtrace ]] && CLI_DEBUG="1"
CLI_SUCCESS=""


cleanup() {
  set +e
  sudo_askpass rm -rf "$CLT_PLACEHOLDER" "$SUDO_ASKPASS" "$SUDO_ASKPASS_DIR"
  sudo --reset-timestamp
  if [ -z "$CLI_SUCCESS" ]; then
    if [ -n "$CLI_STEP" ]; then
      echo "!!! $CLI_STEP FAILED" >&2
    else
      echo "!!! FAILED" >&2
    fi
    if [ -z "$CLI_DEBUG" ]; then
      echo "!!! Run '$0 --debug' for debugging output." >&2
      echo "!!! If you're stuck: file an issue with debugging output at:" >&2
      echo "!!!   $CLI_ISSUES_URL" >&2
    fi
  fi
}

trap "cleanup" EXIT

if [ -n "$CLI_DEBUG" ]; then
  set -x
else
  CLI_QUIET_FLAG="-q"
  Q="$CLI_QUIET_FLAG"
fi

STDIN_FILE_DESCRIPTOR="0"
[ -t "$STDIN_FILE_DESCRIPTOR" ] && CLI_INTERACTIVE="1"

# Set by web/app.rb
# CLI_GIT_NAME=
# CLI_GIT_EMAIL=
# CLI_GITHUB_USER=
# CLI_GITHUB_TOKEN=
CLI_ISSUES_URL='https://github.com/GetLevvel/lvl_cli/issues/new'

# functions for turning off debug for use when handling the user password
clear_debug() {
  set +x
}

reset_debug() {
  if [ -n "$CLI_DEBUG" ]; then
    set -x
  fi
}

abort() { CLI_STEP="";   echo "!!! $*" >&2; exit 1; }
log()   { CLI_STEP="$*"; sudo_refresh; echo "--> $*"; }
logn()  { CLI_STEP="$*"; sudo_refresh; printf -- "--> %s " "$*"; }
logk()  { CLI_STEP="";   echo "OK"; }
escape() {
  printf '%s' "${1//\'/\'}"
}

[ "$USER" = "root" ] && abort "Install the CLI as yourself, not root."
groups | grep $Q -E "\b(admin)\b" || abort "Add $USER to the admin group."


# [TODO] Branding opportunity
# if [ -n "$CLI_GIT_NAME" ] && [ -n "$CLI_GIT_EMAIL" ]; then
#   LOGIN_TEXT=$(escape "Found this computer? Please contact $CLI_GIT_NAME at $CLI_GIT_EMAIL.")
#   echo "$LOGIN_TEXT" | grep -q '[()]' && LOGIN_TEXT="'$LOGIN_TEXT'"
#   sudo_askpass defaults write /Library/Preferences/com.apple.loginwindow \
#     LoginwindowText \
#     "$LOGIN_TEXT"
# fi
# logk

# [TODO] JVF -- this one hurts a little to leave out
# Check and enable full-disk encryption.
# logn "Checking full-disk encryption status:"
# if fdesetup status | grep $Q -E "FileVault is (On|Off, but will be enabled after the next restart)."; then
#   logk
# elif [ -n "$CLI_CI" ]; then
#   echo
#   logn "Skipping full-disk encryption for CI"
# elif [ -n "$CLI_INTERACTIVE" ]; then
#   echo
#   log "Enabling full-disk encryption on next reboot:"
#   sudo_askpass fdesetup enable -user "$USER" \
#     | tee ~/Desktop/"FileVault Recovery Key.txt"
#   logk
# else
#   echo
#   abort "Run 'sudo fdesetup enable -user \"$USER\"' to enable full-disk encryption."
# fi

# Install the Xcode Command Line Tools.
if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]
then
  log "Please install the XCode Command Line Tools to acquire git binaries."
  # [TODO] We can restore this if we are interested in retaining sudo stuff
  # CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  # sudo_askpass touch "$CLT_PLACEHOLDER"
  #
  # CLT_PACKAGE=$(softwareupdate -l | \
  #               grep -B 1 "Command Line Tools" | \
  #               awk -F"*" '/^ *\*/ {print $2}' | \
  #               sed -e 's/^ *Label: //' -e 's/^ *//' | \
  #               sort -V |
  #               tail -n1)
  # sudo_askpass softwareupdate -i "$CLT_PACKAGE"
  # sudo_askpass rm -f "$CLT_PLACEHOLDER"
  # if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]
  # then
  #   if [ -n "$CLI_INTERACTIVE" ]; then
  #     echo
  #     logn "Requesting user install of Xcode Command Line Tools:"
  #     xcode-select --install
  #   else
  #     echo
  #     abort "Run 'xcode-select --install' to install the Xcode Command Line Tools."
  #   fi
  # fi
  # logk
fi

# Check if the Xcode license is agreed to and agree if not.
# xcode_license() {
#   if /usr/bin/xcrun clang 2>&1 | grep $Q license; then
#     if [ -n "$CLI_INTERACTIVE" ]; then
#       logn "Asking for Xcode license confirmation:"
#       sudo_askpass xcodebuild -license
#       logk
#     else
#       abort "Run 'sudo xcodebuild -license' to agree to the Xcode license."
#     fi
#   fi
# }
# xcode_license

# Setup Git configuration.
# [TODO] This is the first bit to come back (if we are restoring anything)
# logn "Configuring Git:"
# if [ -n "$CLI_GIT_NAME" ] && ! git config user.name >/dev/null; then
#   git config --global user.name "$CLI_GIT_NAME"
# fi
#
# if [ -n "$CLI_GIT_EMAIL" ] && ! git config user.email >/dev/null; then
#   git config --global user.email "$CLI_GIT_EMAIL"
# fi
#
# if [ -n "$CLI_GITHUB_USER" ] && [ "$(git config github.user)" != "$CLI_GITHUB_USER" ]; then
#   git config --global github.user "$CLI_GITHUB_USER"
# fi
#
# # Squelch git 2.x warning message when pushing
# if ! git config push.default >/dev/null; then
#   git config --global push.default simple
# fi

# [TODO]
# JVF and Ian think this stanza has a lot of promise, but too potentially disruptive to introduce in this way.

# Setup GitHub HTTPS credentials.
# if git credential-osxkeychain 2>&1 | grep $Q "git.credential-osxkeychain"
# then
#   if [ "$(git config --global credential.helper)" != "osxkeychain" ]
#   then
#     git config --global credential.helper osxkeychain
#   fi
#
#   if [ -n "$CLI_GITHUB_USER" ] && [ -n "$CLI_GITHUB_TOKEN" ]
#   then
#     printf "protocol=https\\nhost=github.com\\n" | git credential-osxkeychain erase
#     printf "protocol=https\\nhost=github.com\\nusername=%s\\npassword=%s\\n" \
#           "$CLI_GITHUB_USER" "$CLI_GITHUB_TOKEN" \
#           | git credential-osxkeychain store
#   fi
# fi
logk

log "Your CLI is now installed."
