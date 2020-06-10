#!/bin/bash
#/ Usage: bin/install-cli.sh [--debug]
#/ Install development dependencies on macOS.
set -e

BLUE='\e[;34m'
ORANGE='\e[1;31m'
printf "${BLUE}██▄▄                   ███                 ███                          ███   ███\n"
printf "${BLUE}▀▀█████▄▄              ███                 ███                 ▄▄▄▄▄    ███      \n"
printf "${BLUE}     ▀▀████▄▄          ███   ▀██    ▐██▀   ███               ▄███▀▀██   ███   ███\n"
printf "${BLUE}       ▄▄████▀▀        ███    ███   ██▌    ███              ▐██▀        ███   ███\n"
printf "${BLUE}  ▄▄▄████▀▀            ███     ███ ███     ███              ▐██▄        ███   ███\n"
printf "${BLUE}████▀▀▀    ${ORANGE}▄▄▄▄▄▄▄▄▄▄${BLUE}  ███      █████      ███   ${ORANGE}▄▄▄▄▄▄▄▄${BLUE}    ▀███▄▄██   ███   ███\n"
printf "${BLUE}▀▀      ${ORANGE}▀▀▀▀▀▀▀▀▀▀▀▀▀${BLUE}  ▀▀▀       ▀▀▀       ▀▀▀   ${ORANGE}▀▀▀▀▀▀▀▀▀▀${BLUE}    ▀▀▀▀▀    ▀▀▀   ▀▀▀\e[0m\n"

[[ "$1" = "--debug" || -o xtrace ]] && CLI_DEBUG="1"
CLI_SUCCESS=""

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
# CLI_LOG_TOKEN=
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
log()   { CLI_STEP="$*"; echo "--> $*"; }
logn()  { CLI_STEP="$*"; printf -- "--> %s " "$*"; }
logk()  { CLI_STEP="";   echo "OK"; }
escape() {
  printf '%s' "${1//\'/\'}"
}

[ "$USER" = "root" ] && abort "Install the CLI as yourself, not root."
groups | grep $Q -E "\b(admin)\b" || abort "Add $USER to the admin group."


# Install the Xcode Command Line Tools.
if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ]
then
  log "Please install the XCode Command Line Tools to acquire git binaries."
fi

logk

mkdir $HOME/.lvl_cli
cd $HOME/.lvl_cli
git clone https://$CLI_GITHUB_USER:$CLI_GITHUB_TOKEN@github.com/GetLevvel/lvl_cli.git repo
cd $HOME/.lvl_cli/repo
git checkout -b release -t origin/release
npm link --force
cd $HOME/.lvl_cli/repo/packages/lvl_cli
npm link --force

lvl login $CLI_GITHUB_TOKEN
lvl log:set-token $CLI_LOG_TOKEN

log "lvl_cli has been installed successfully! Run lvl -h to get started."
