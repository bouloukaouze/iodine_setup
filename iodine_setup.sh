#!/bin/bash

BOLD="\e[1m"
GRAY="\e[1;30m"
NORMAL="\e[0m"
BLUE="\e[34m"
RED="\e[31m"
GREEN="\e[32m"

help () {
    echo "Usage: iodined_tun.sh domain [gateway]"
    exit
}

check_iodine () {
    if [[ $(ifconfig | grep dns0 | wc -l) -ge 1 ]]; then
        running=true
    else
        running=false
    fi
}

ping_gateway () {
    if ping -c 1 "$gateway" >/dev/null
    then
        echo -e "${BOLD}${GREEN}[+] ${BLUE}$gateway${GREEN} reachable${NORMAL}"
    else
        echo -e "${BOLD}${RED}[!] Could not reach $gateway${NORMAL}"
        exit
    fi
}

set_gateway () {
    gateway="$(ip a | grep dns0 | grep inet | awk '{print $2}' | cut -d. -f1-3).1"
    echo -e "${BOLD}${GREEN}[+] Automatically picking ${BLUE}$gateway${GREEN} as gateway${NORMAL}"
}

setup_proxy () {
    echo -e "$GRAY"
    ssh -o "StrictHostKeyChecking=no" -f -N -C -D 1234 "root@$gateway"
    echo -e "$NORMAL"
    echo -ne "${BOLD}${GREEN}[+] SOCKS5 proxy running on port ${BLUE}1243${NORMAL}"
}

start_iodine () {
    [[ -z "$domain" ]] && help
    read -s -p "Enter tunnel password: " password
    echo
    echo -e "\n${BOLD}Starting ${BLUE}iodine${NORMAL}${BOLD}...${NORMAL}"
    echo -e "$GRAY"
    iodine -P "$password" "$domain"
    echo -e "$NORMAL"
    check_iodine
    if $running; then
        echo -e "${BOLD}${GREEN}[+] ${BLUE}Iodine${GREEN} started successfully${NORMAL}"
    else
        echo -e "${BOLD}${RED}[!] An error occured while starting ${BLUE}iodine${NORMAL}"
        exit
    fi
    [[ -z "$gateway" ]] && set_gateway
    ping_gateway
    setup_proxy
}

stop_iodine () {
    echo -e "\n${BOLD}Stopping ${BLUE}iodine${NORMAL}${BOLD}...${NORMAL}"
    killall iodine && sleep 1
    echo -e "${BOLD}Stopping ${BLUE}SOCKS5 proxy${NORMAL}${BOLD}...${NORMAL}"
    ps -ef | grep "ssh -o StrictHostKeyChecking=no -f -N -C -D 1234" | head -n 1 | awk '{print $2}' | xargs kill
    check_iodine
    if $running; then
        echo -e "\n${BOLD}${RED}[!] ${BLUE}Iodine${RED} was not stopped successfully${NORMAL}"
        exit
    else
        echo -e "\n${BOLD}${GREEN}[+] ${BLUE}Iodine${GREEN} stopped successfully"
    fi
}

check_iodine
if $running; then
    stop_iodine
else
    domain="$1"
    gateway="$2"
    start_iodine
fi

