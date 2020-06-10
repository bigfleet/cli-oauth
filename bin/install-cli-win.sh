#/ Usage: bash install-cli-win.sh [--debug]
#/ Install development dependencies on Windows.
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

# Turn on emojis
chcp.com 65001

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

rm -rf ~/appdata/local/levvel/.lvl_cli
mkdir -p ~/appdata/local/levvel/.lvl_cli
cd ~/appdata/local/levvel/.lvl_cli
git clone https://$CLI_GITHUB_USER:$CLI_GITHUB_TOKEN@github.com/GetLevvel/lvl_cli.git repo
cd ~/appdata/local/levvel/.lvl_cli/repo
git checkout -b release -t origin/release
npm link --force
cd ~/appdata/local/levvel/.lvl_cli/repo/packages/lvl_cli
npm link --force

lvl login $CLI_GITHUB_TOKEN
lvl log:set-token $CLI_LOG_TOKEN

printf "${ORANGE}lvl_cli has been installed successfully! Run lvl -h to get started.\e[0m"