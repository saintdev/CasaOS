#!/bin/sh
###
 # @Author:  LinkLeong link@icewhale.com
 # @Date: 2022-06-30 10:08:33
 # @LastEditors: LinkLeong
 # @LastEditTime: 2022-07-01 11:17:54
 # @FilePath: /CasaOS/shell/delete-old-service.sh
 # @Description:
###

[ "$(id -u)" -ne 0 ] && sudo_cmd="sudo"

# SYSTEM INFO
readonly UNAME_M="$(uname -m)"

# CasaOS PATHS
readonly CASA_REPO=IceWhaleTech/CasaOS
readonly CASA_UNZIP_TEMP_FOLDER=/tmp/casaos
readonly CASA_BIN=casaos
readonly CASA_BIN_PATH=/usr/bin/casaos
readonly CASA_CONF_PATH=/etc/casaos.conf
readonly CASA_SERVICE_PATH=/etc/systemd/system/casaos.service
readonly CASA_HELPER_PATH=/usr/share/casaos/shell/
readonly CASA_USER_CONF_PATH=/var/lib/casaos/conf/
readonly CASA_DB_PATH=/var/lib/casaos/db/
readonly CASA_TEMP_PATH=/var/lib/casaos/temp/
readonly CASA_LOGS_PATH=/var/log/casaos/
readonly CASA_PACKAGE_EXT=".tar.gz"
readonly CASA_RELEASE_API="https://api.github.com/repos/${CASA_REPO}/releases"
readonly CASA_OPENWRT_DOCS="https://github.com/IceWhaleTech/CasaOS-OpenWrt"

readonly COLOUR_RESET='\e[0m'
readonly COLOUR_GREEN='\e[38;5;154m' # green  		| Lines, bullets and separators
readonly COLOUR_WHITE='\e[1m'        # Bold white	| Main descriptions
readonly COLOUR_GREY='\e[90m'        # Grey  		| Credits
readonly COLOUR_RED='\e[91m'         # Red   		| Update notifications Alert
readonly COLOUR_YELLOW='\e[33m'      # Yellow		| Emphasis

Target_Arch=""
Target_Distro="debian"
Target_OS="linux"
Casa_Tag=""


#######################################
# Custom printing function
# Globals:
#   None
# Arguments:
#   $1 0:OK   1:FAILED  2:INFO  3:NOTICE
#   message
# Returns:
#   None
#######################################

Show() {
    case $1 in
        0 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_GREEN}  OK  $COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;  # OK
        1 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_RED}FAILED$COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;    # FAILED
        2 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_GREEN} INFO $COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;  # INFO
        3 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_YELLOW}NOTICE$COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";; # NOTICE
    esac
}

Warn() {
    echo -e "${COLOUR_RED}$1$COLOUR_RESET"
}

UseSystemd() {
    # shellcheck source=/dev/null
    . /etc/os-release

    [ "${ID}" = "alpine" ] && return 1

    return 0
}

Service() {
  if UseSystemd; then
    $sudo_cmd systemctl "$1" "$2"
  else
    local svcname
    svcname="${2%.service}"
    cmd="$1"

    expr "${svcname}" : '.*\.socket$' >/dev/null || return 0 # OpenRC doesn't have socket services.

    case $cmd in
      "enable" ) $sudo_cmd rc-update add "$svcname" default;;
      "disable" ) $sudo_cmd rc-update del "$svcname";;
      * ) $sudo_cmd rc-service "$svcname" "$cmd";;
    esac
  fi
}

# 0 Check_exist
Check_Exist() {
    #Create Dir
    Show 2 "Create Folders."
    ${sudo_cmd} mkdir -p ${CASA_HELPER_PATH}
    ${sudo_cmd} mkdir -p ${CASA_LOGS_PATH}
    ${sudo_cmd} mkdir -p ${CASA_USER_CONF_PATH}
    ${sudo_cmd} mkdir -p ${CASA_DB_PATH}
    ${sudo_cmd} mkdir -p ${CASA_TEMP_PATH}


    Show 2 "Start cleaning up the old version."

    ${sudo_cmd} rm -rf /usr/lib/systemd/system/casaos.service

    ${sudo_cmd} rm -rf /lib/systemd/system/casaos.service

    ${sudo_cmd} rm -rf /usr/local/bin/${CASA_BIN}

    #Clean
    if [ -d "/casaOS" ]; then
        ${sudo_cmd} rm -rf /casaOS
    fi
    Show 0 "Clearance completed."

    Service restart "${CASA_BIN}"
}
Check_Exist
