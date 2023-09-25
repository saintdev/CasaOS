#!/bin/sh

set -e

readonly CASA_SERVICES="casaos devmon.devmon"

readonly CASA_EXEC=casaos
readonly CASA_CONF=/etc/casaos/casaos.conf
readonly CASA_URL=/var/run/casaos/casaos.url
readonly CASA_SERVICE_INITD=/etc/init.d/casaos

# Old Casa Files
readonly CASA_PATH=/casaOS
readonly CASA_CONF_PATH_OLD=/etc/casaos.conf

readonly COLOUR_GREEN='\e[38;5;154m' # green  		| Lines, bullets and separators
readonly COLOUR_WHITE='\e[1m'        # Bold white	| Main descriptions
readonly COLOUR_GREY='\e[90m'        # Grey  		| Credits
readonly COLOUR_RED='\e[91m'         # Red   		| Update notifications Alert
readonly COLOUR_YELLOW='\e[33m'      # Yellow		| Emphasis

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

trap 'onCtrlC' INT
onCtrlC() {
    echo -e "${COLOUR_RESET}"
    exit 1
}

Detecting_CasaOS() {
    if [ ! -x "$(command -v ${CASA_EXEC})" ]; then
        Show 2 "CasaOS is not detected, exit the script."
        exit 1
    else
        Show 0 "This script will delete the containers you no longer use, and the CasaOS configuration files."
    fi
}

Uninstall_Container() {
    if [ "${UNINSTALL_ALL_CONTAINER}" = "true" ] && [ "$(docker ps -aq)" != "" ]; then
        Show 2 "Start deleting containers."
        docker stop "$(docker ps -aq)" || Show 1 "Failed to stop all containers."
        docker rm "$(docker ps -aq)" || Show 1 "Failed to delete all containers."
    fi
}

Remove_Images() {
    if [ "${REMOVE_IMAGES}" = "all" ] && [ "$(docker images -q)" != "" ]; then
        Show 2 "Start deleting all images."
        docker rmi "$(docker images -q)" || Show 1 "Failed to delete all images."
    elif [ "${REMOVE_IMAGES}" = "unuse" ] && [ "$(docker images -q)" != "" ]; then
        Show 2 "Start deleting unuse images."
        docker image prune -af || Show 1 "Failed to delete unuse images."
    fi
}


Uninstall_Casaos() {

    for SERVICE in ${CASA_SERVICES}; do
        Show 2 "Stopping ${SERVICE}..."
        rc-service --ifexists "${SERVICE}" stop
        rc-update del "${SERVICE}"
    done

    # Remove Service file
    if [ -f "${CASA_SERVICE_INITD}" ]; then
        rm -rvf "${CASA_SERVICE_INITD}"
    fi

    # Old Casa Files
    if [ -d "${CASA_PATH}" ]; then
        rm -rvf "${CASA_PATH}" || Show 1 "Failed to delete legacy CasaOS files."
    fi

    if [ -f "${CASA_CONF_PATH_OLD}" ]; then
        rm -rvf "${CASA_CONF_PATH_OLD}"
    fi

    # New Casa Files
    if [ "${REMOVE_APP_DATA}" = "true" ]; then
        rm -rvf /DATA/AppData || Show 1 "Failed to delete AppData."
    fi

    rm -rvf "$(which ${CASA_EXEC})" || Show 3 "Failed to remove ${CASA_EXEC}"
    rm -rvf "${CASA_CONF}" || Show 3 "Failed to remove ${CASA_CONF}"
    rm -rvf "${CASA_URL}" || Show 3 "Failed to remove ${CASA_URL}"

    rm -rvf /var/lib/casaos/app_category.json
    rm -rvf /var/lib/casaos/app_list.json
    rm -rvf /var/lib/casaos/docker_root
}

Detecting_CasaOS

while true; do
    echo -n -e "         ${COLOUR_YELLOW}Do you want delete all containers? Y/n :${COLOUR_RESET}"
    read -r input
    case $input in
    [yY][eE][sS] | [yY])
        UNINSTALL_ALL_CONTAINER=true
        break
        ;;
    [nN][oO] | [nN])
        UNINSTALL_ALL_CONTAINER=false
        break
        ;;
    *)
        Warn "         Invalid input..."
        ;;
    esac
done

if [ "${UNINSTALL_ALL_CONTAINER}" = "true" ]; then
    while true; do
        echo -n -e "         ${COLOUR_YELLOW}Do you want delete all images? Y/n :${COLOUR_RESET}"
        read -r input
        case $input in
        [yY][eE][sS] | [yY])
            REMOVE_IMAGES="all"
            break
            ;;
        [nN][oO] | [nN])
            REMOVE_IMAGES="none"
            break
            ;;
        *)
            Warn "         Invalid input..."
            ;;
        esac
    done

    while true; do
        echo -n -e "         ${COLOUR_YELLOW}Do you want delete all AppData of CasaOS? Y/n :${COLOUR_RESET}"
        read -r input
        case $input in
        [yY][eE][sS] | [yY])
            REMOVE_APP_DATA=true
            break
            ;;
        [nN][oO] | [nN])
            REMOVE_APP_DATA=false
            break
            ;;
        *)
            Warn "         Invalid input..."
            ;;
        esac
    done
else
    while true; do
        echo -n -e "         ${COLOUR_YELLOW}Do you want to delete all images that are not used by the container? Y/n :${COLOUR_RESET}"
        read -r input
        case $input in
        [yY][eE][sS] | [yY])
            REMOVE_IMAGES="unuse"
            break
            ;;
        [nN][oO] | [nN])
            REMOVE_IMAGES="none"
            break
            ;;
        *)
            Warn "         Invalid input..."
            ;;
        esac
    done
fi

Uninstall_Container
Remove_Images
Uninstall_Casaos
