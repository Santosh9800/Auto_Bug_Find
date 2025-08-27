#!/bin/bash
# Tool Installer & System Info
# Author: Santosh | Channel: Master in White Devil
# Version: 0.0.1

# Colors
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

# Banner
banner() {
    clear
    echo -e "${RED}"
    echo "███████╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███████╗██╗  ██╗"
    echo "██╔════╝██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗██╔════╝██║  ██║"
    echo "███████╗███████║██╔██╗ ██║   ██║   ██║   ██║███████╗███████║"
    echo "╚════██║██╔══██║██║╚██╗██║   ██║   ██║   ██║╚════██║██╔══██║"
    echo "███████║██║  ██║██║ ╚████║   ██║   ╚██████╔╝███████║██║  ██║"
    echo "╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═╝"
    echo -e "${RESET}"
    echo -e "${CYAN}Santosh | Channel: Master in White Devil${RESET}"
    echo -e "${YELLOW}Version 0.0.1 (Next: 0.0.2 coming soon...)${RESET}"
    echo
}

# System Info
system_info() {
    echo -e "${GREEN}[+] Collecting System Information...${RESET}"
    echo -e "${CYAN}OS:$(uname -o)${RESET}"
    echo -e "${CYAN}Kernel:$(uname -r)${RESET}"
    echo -e "${CYAN}Architecture:$(uname -m)${RESET}"
    echo -e "${CYAN}Hostname:$(hostname)${RESET}"

    IP=$(curl -s ifconfig.me)
    LOC=$(curl -s ipinfo.io/$IP/city)
    COUNTRY=$(curl -s ipinfo.io/$IP/country)

    echo -e "${CYAN}Public IP:${IP}${RESET}"
    echo -e "${CYAN}Location:${LOC}, ${COUNTRY}${RESET}"
    echo
}

# Install Tools
install_tools() {
    echo -e "${GREEN}[+] Installing Required Tools...${RESET}"
    sudo apt update -y
    sudo apt install -y golang-go git curl wget build-essential

    # Go Path
    export PATH=$PATH:$(go env GOPATH)/bin

    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    go install github.com/s0md3v/dalfox/v2@latest
    go install github.com/s0md3v/Arjun@latest

    echo -e "${YELLOW}[✔] All tools installed successfully!${RESET}"
}

# Menu
menu() {
    banner
    echo -e "${GREEN}[1] Show System Info${RESET}"
    echo -e "${GREEN}[2] Install All Tools${RESET}"
    echo -e "${GREEN}[3] Exit${RESET}"
    echo
    read -p "Choose an option: " choice

    case $choice in
        1) system_info ;;
        2) install_tools ;;
        3) exit 0 ;;
        *) echo -e "${RED}Invalid option!${RESET}" ;;
    esac
}

# Run Menu
menu

