#!/usr/bin/env bash
# Recon Pipeline with Hacker Style Banner
# Author: Santosh | Channel: Master in White Devil
# Version: 0.0.1 (Next: 0.0.2 Coming Soon)

set -Eeuo pipefail
IFS=$'\n\t'

# -----------------------------
# Hacker Style Banner
# -----------------------------
banner() {
clear
echo -e "\e[31m"
echo "███████╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███████╗██╗  ██╗"
echo "██╔════╝██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗██╔════╝██║  ██║"
echo "███████╗███████║██╔██╗ ██║   ██║   ██║   ██║███████╗███████║"
echo "╚════██║██╔══██║██║╚██╗██║   ██║   ██║   ██║╚════██║██╔══██║"
echo "███████║██║  ██║██║ ╚████║   ██║   ╚██████╔╝███████║██║  ██║"
echo "╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═╝"
echo -e "\e[36m"
echo "             Santosh | Channel: Master in White Devil"
echo -e "\e[33m"
echo "             Version: 0.0.1  (Next: 0.0.2 Coming Soon)"
echo -e "\e[0m"
echo
}
banner

# -----------------------------
# System & User Info
# -----------------------------
log_sysinfo(){
  echo -e "\e[32m[+] Collecting System Info...\e[0m"

  # Public IP
  MYIP=$(curl -s ifconfig.me || echo "Unknown")
  echo "[*] Public IP        : $MYIP"

  # OS Detect
  OSINFO=$(uname -o 2>/dev/null || uname -s)
  KERNEL=$(uname -r)
  echo "[*] Operating System : $OSINFO ($KERNEL)"

  # Location (GeoIP lookup via ipinfo.io)
  if [[ "$MYIP" != "Unknown" ]]; then
    GEO=$(curl -s https://ipinfo.io/$MYIP/json || true)
    CITY=$(echo "$GEO" | grep -oP '"city":\s*"\K[^"]+')
    REGION=$(echo "$GEO" | grep -oP '"region":\s*"\K[^"]+')
    COUNTRY=$(echo "$GEO" | grep -oP '"country":\s*"\K[^"]+')
    LOC=$(echo "$GEO" | grep -oP '"loc":\s*"\K[^"]+')
    echo "[*] Location         : ${CITY:-N/A}, ${REGION:-N/A}, ${COUNTRY:-N/A}"
    echo "[*] Coordinates      : ${LOC:-N/A}"
  fi

  # Current Time
  echo "[*] Current Time     : $(date)"
  echo
}
log_sysinfo

# -----------------------------
# Defaults
# -----------------------------
DOMAIN=""
OUTDIR=""
FULL_PORTS=false
DO_NMAP=false
THREADS_HTTPX=50
THREADS_KATANA=20
THREADS_ARJUN=20

usage(){
  cat <<USAGE
Recon Pipeline
==============
Usage:
  $(basename "$0") -d <domain> [-o <outdir>] [--full-ports] [--nmap]

Options:
  -d, --domain       Root domain (e.g., example.com)
  -o, --outdir       Output directory (default: recon_<domain>_<YYYYmmdd_HHMMSS>)
  --full-ports       Scan all 1-65535 ports with naabu (default: top 1000 ports)
  --nmap             Run an additional nmap service scan on live hosts
  -h, --help         Show this help and exit

Dependencies (install if missing):
  subfinder, httpx, dnsx, naabu, katana, arjun, dalfox, nuclei
USAGE
}

log(){ printf "[+] %s\n" "$*"; }
warn(){ printf "[!] %s\n" "$*" >&2; }

need(){
  if ! command -v "$1" >/dev/null 2>&1; then
    warn "Missing dependency: $1"; MISSING=1
  fi
}

# -----------------------------
# Parse args
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domain) DOMAIN="$2"; shift 2;;
    -o|--outdir) OUTDIR="$2"; shift 2;;
    --full-ports) FULL_PORTS=true; shift;;
    --nmap) DO_NMAP=true; shift;;
    -h|--help) usage; exit 0;;
    *) warn "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -z "$DOMAIN" ]] && { warn "Domain is required"; usage; exit 1; }

TS=$(date +%Y%m%d_%H%M%S)
OUTDIR=${OUTDIR:-"recon_${DOMAIN}_${TS}"}
mkdir -p "$OUTDIR"
cd "$OUTDIR"

# -----------------------------
# Check deps
# -----------------------------
MISSING=0
need subfinder
need httpx
need dnsx
need naabu
need katana
need arjun
need dalfox
need nuclei
if [[ $MISSING -eq 1 ]]; then
  warn "One or more dependencies are missing. Install them before running."; exit 2
fi

# -----------------------------
# 1) Subdomains
# -----------------------------
log "Enumerating subdomains ..."
subfinder -d "$DOMAIN" -all -silent -o subdomains.txt || true
sort -u subdomains.txt -o subdomains.txt
log "Subdomains saved to subdomains.txt"

# -----------------------------
# 2) Live hosts + Tech detection
# -----------------------------
log "Detecting live hosts & technologies ..."
httpx -l subdomains.txt -silent -status-code -title -tech-detect -threads "$THREADS_HTTPX" -o web_tech.txt || true
awk '{print $1}' web_tech.txt > live.txt || true
sort -u live.txt -o live.txt

# -----------------------------
# 3) Resolve to IPs
# -----------------------------
log "Resolving IPs ..."
dnsx -l subdomains.txt -a -resp -silent | tee resolved.txt >/dev/null || true
awk '{print $2}' resolved.txt | tr -d '[]' | sort -u > ips.txt || true

# -----------------------------
# 4) Port Scan
# -----------------------------
if [[ -s ips.txt ]]; then
  PORT_ARG="-top-ports 1000"
  $FULL_PORTS && PORT_ARG="-p -"
  log "Scanning ports with naabu ..."
  naabu -nc -list ips.txt ${PORT_ARG} -o ports.txt || true
fi

# -----------------------------
# 5) Crawl endpoints
# -----------------------------
if [[ -s live.txt ]]; then
  log "Crawling endpoints with katana ..."
  katana -list live.txt -silent -ef js,png,jpg,jpeg,gif,svg,woff,woff2 -o endpoints.txt -d 2 -c "$THREADS_KATANA" || true
  sort -u endpoints.txt -o endpoints.txt
fi

# -----------------------------
# 6) Discover parameters
# -----------------------------
if [[ -s endpoints.txt ]]; then
  log "Discovering parameters with arjun ..."
  arjun -i endpoints.txt -t "$THREADS_ARJUN" -oT params.txt || true
  sort -u params.txt -o params.txt
fi

# -----------------------------
# 7) XSS fuzzing
# -----------------------------
if [[ -s params.txt ]]; then
  log "Fuzzing XSS with dalfox ..."
  dalfox file params.txt -o dalfox_xss.txt || true
fi

# -----------------------------
# 8) Nuclei scanning
# -----------------------------
if [[ -s live.txt ]]; then
  log "Running nuclei scans ..."
  nuclei -l live.txt -as -o nuclei_all.txt || true
fi

# -----------------------------
# 9) Optional: Nmap service scan
# -----------------------------
if $DO_NMAP && [[ -s ips.txt ]]; then
  if command -v nmap >/dev/null 2>&1; then
    log "Running nmap service detection ..."
    nmap -iL ips.txt -sV -T4 --open -oN nmap_services.txt || true
  fi
fi

# -----------------------------
# Summary
# -----------------------------
log "Recon Completed!"
log "Results in: $(pwd)"

