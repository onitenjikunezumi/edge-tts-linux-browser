#!/usr/bin/env bash
#
# Project:     EDGE-TTS-LINUX-BROWSER
# Description: Installation script for edge-tts and speech-dispatcher integration.
# Author:      onitenjikunezumi
# Repository:  https://github.com/onitenjikunezumi/edge-tts-linux-browser
#

TIMESTAMP=$(date +"%Y_%m%d"_%H%M)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
EDGETTS_DIR=~/.local/share/edge-tts-linux-browser
CONFIG_DIR=~/.config/speech-dispatcher
FL_URL="https://feedlingo.yagiful.com"

RESET=$(tput sgr0)
BOLD=$(tput bold)
REV=$(tput smso)
REV_END=$(tput rmso)

#

title(){
    cat <<EOF

$BOLD# $1$RESET

EOF
}

section(){
    cat <<EOF

$BOLD## $1$RESET

EOF
}

subsection(){
    cat <<EOF

$BOLD### $1$RESET

EOF
}

yesno(){
    local choice
    
    while true; do
        read -p "$BOLD> $1 (y/n): $RESET" choice
        case "$choice" in
            [yY]* ) return 0 ;;
            [nN]* ) return 1 ;;
            * ) echo "Please answer y or n." ;;
        esac
    done
}

new_dir(){
    local dir="$1"
    
    if [ -d "$dir" ]; then
        echo "Warning: Directory '$dir' already exists."
        local choice
        read -p "$BOLD> Choose an action: [s]kip or [b]ackup? (s/b): $RESET" choice
        case "$choice" in
            [sS]* )
                echo "Skipping..."
                return 1
                ;;
            [bB]* )
                local backup_dir="${dir}_${TIMESTAMP}"
                echo "Backing up '$dir' to '$backup_dir'..."
                mv "$dir" "$backup_dir"
                ;;
            * )
                echo "Invalid choice. Skipping by default."
                return 1
                ;;
        esac
    fi

    mkdir -p "$dir"
}

#

title "EDGE-TTS-LINUX-BROWSER"

cat <<EOF
This script installs edge-tts and configures your Linux system to support high-quality text-to-speech.
It also enables your web browser to use natural edge-tts voices via the Web Speech API.

Files and configurations will be installed in the following locations:

- $BOLD${EDGETTS_DIR}:$RESET edge-tts core and speech-dispatcher wrapper scripts.
- $BOLD${CONFIG_DIR}:$RESET speech-dispatcher configuration files.

Installation steps:

1. Set up ${EDGETTS_DIR}
2. Set up ${CONFIG_DIR}
3. Test audio output in the terminal
4. Test audio output in the browser (Optional; includes a look at FeedDeLingo)

EOF

if ! yesno "Do you want to proceed with the installation?"; then
    echo "Installation aborted."
    exit 1
fi

#

IS_RPI=1
if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model; then
    IS_RPI=0
fi

IS_TRIXIE=1
if [ -f /etc/os-release ] && grep -q "VERSION_CODENAME=trixie" /etc/os-release; then
    IS_TRIXIE=0
fi

if [ "$IS_RPI" != "0" -o "$IS_TRIXIE" != "0" ]; then
    subsection "Warning: This script is intended for Raspberry Pi OS 13 (Trixie)"
    if yesno "OS mismatch detected. The script may work on other Linux distributions, but it is untested. Do you want to continue anyway?"; then
        echo "Continuing installation..."
    else
        echo "Installation aborted."
        exit 1
    fi
fi 

#

apt_packages=""
if ! command -v python3 >/dev/null 2>&1; then
    apt_packages="$apt_packages python3 python3-venv"
else
    if ! python3 -m venv --help >/dev/null 2>&1; then
        apt_packages="$apt_packages python3-venv"
    fi
fi

if ! command -v spd-say >/dev/null 2>&1; then
    apt_packages="$apt_packages speech-dispatcher"
fi

if ! command -v mpg123 >/dev/null 2>&1; then
    apt_packages="$apt_packages mpg123"
fi

if [ -n "$apt_packages" ]; then
    apt_packages_installed=1
    subsection "The following packages are missing:"
    echo -e "packages: $apt_packages\n"
    if command -v apt >/dev/null 2>&1; then    
        if yesno "Would you like to install them now?"; then
            if sudo apt update && sudo apt install -y $apt_packages; then
                apt_packages_installed=0
            else
                echo "Error: Package installation failed. Please check your permissions or network."
            fi
        fi
    fi

    if [ "$apt_packages_installed" != 0 ]; then
	echo "Please install the required packages manually before running this script again."
	echo "Installation aborted."
	exit 1
    fi
fi

#

section "1. $EDGETTS_DIR: Installing edge-tts and the 'edge-tts-dispatch' wrapper"
if new_dir "$EDGETTS_DIR"; then
    cd "$EDGETTS_DIR"
    python3 -m venv venv
    source venv/bin/activate
    pip install edge-tts
    deactivate
    cp -pr "$SCRIPT_DIR/edge-tts-dispatch" .
    chmod +x edge-tts-dispatch
fi

#

section "2. $CONFIG_DIR: Configuring speech-dispatcher"
if new_dir "$CONFIG_DIR"; then
    cd "$CONFIG_DIR"
    echo "Copying configuration files..."
    cp -pr "$SCRIPT_DIR/speech-dispatcher"/* .
fi

#

section "3. Test audio output in the terminal"
read -p "(Press Enter to start the test) " choice
echo "Stopping existing speech-dispatcher processes..."
killall speech-dispatcher >/dev/null 2>&1
sleep 1
echo "Speaking a test phrase using spd-say..."
spd-say -l en-us "This is a test of Edge-TTS using Speech Dispatcher." -w
if ! yesno "Did you hear the voice clearly?"; then
    cat <<EOF

Configuration failed.

To uninstall, please remove the following directories:
- ${EDGETTS_DIR}
- ${CONFIG_DIR}

EOF
    exit 1
fi

#

FEEDS="%7B%22version%22%3A1%2C%22feeds%22%3A%5B%7B%22url%22%3A%22http%3A%2F%2Ffeeds.bbci.co.uk%2Fnews%2Fworld%2Frss.xml%22%2C%22name%22%3A%22EN%3A%20BBC%20News%20-%20World%20News%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fnews.yahoo.com%2Frss%2Fworld%22%2C%22name%22%3A%22EN%3A%20Yahoo%20News%20-%20Latest%20News%20%26%20Headlines%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.reforma.com%2Frss%2Fportada.xml%22%2C%22name%22%3A%22ES%3A%20Reforma%20(News)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.elpais.com%2Fmrss-s%2Fpages%2Fep%2Fsite%2Felpais.com%2Fportada%22%2C%22name%22%3A%22ES%3A%20EL%20PA%C3%8DS%3A%20el%20peri%C3%B3dico%20global%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.lefigaro.fr%2Frss%2Ffigaro_actualites.xml%22%2C%22name%22%3A%22FR%3A%20Le%20Figaro%20-%20Actualit%C3%A9%20en%20direct%20et%20informations%20en%20continu%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.cms.handelsblatt.com%2Fschlagzeilen%22%2C%22name%22%3A%22DE%3A%20Handelsblatt%20Schlagzeilen%20(News)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.bhaskar.com%2Frss-v1--category-1061.xml%22%2C%22name%22%3A%22HI%3A%20Dainik%20Bhaskar%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fnews.livedoor.com%2Ftopics%2Frss%2Ftop.xml%22%2C%22name%22%3A%22JA%3A%20Livedoor%20News%20(News%20Aggregation%20Site)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fhnrss.org%2Fbest%22%2C%22name%22%3A%22EN%3A%20Hacker%20News%3A%20Best%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.arstechnica.com%2Farstechnica%2Findex%22%2C%22name%22%3A%22EN%3A%20Ars%20Technica%20-%20All%20content%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Frocketnews24.com%2Ffeed%2F%22%2C%22name%22%3A%22JA%3A%20RocketNews24%20(Quirky%20Japan%20News)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fsoranews24.com%2Ffeed%2F%22%2C%22name%22%3A%22EN%3A%20SoraNews24%20%20-%20the%20English-language%20sister%20site%20of%20RocketNews24%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fanimeanime.jp%2Frss20%2Findex.rdf%22%2C%22name%22%3A%22JA%3A%20Anime!%20Anime!%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%5D%7D"

section "4. Test audio output in the browser"

if command -v "chromium-browser" >/dev/null 2>&1; then
    browser="chromium-browser"
    flag=0
elif command -v "chromium" >/dev/null 2>&1; then
    browser="chromium"
    flag=0
elif command -v "firefox" >/dev/null 2>&1; then
    browser="firefox"
    flag=1
else
    echo "No supported browser detected."
    echo "Skipping browser test."
    exit 1
fi

echo -e "Detected browser: $browser\n"
if [ "$flag" = "0" ]; then
    cat <<EOF
${BOLD}To use the Web Speech API in this browser, it must be launched with the following flag:

${REV}$browser --enable-speech-dispatcher${RESET}

You can configure your browser to use this flag by default. See README.md for details.

EOF
fi

if ! yesno "Would you like to launch the browser with the required flag to test the Web Speech API?"; then
    echo "Skipping browser test."
    exit 1
fi

cat <<EOF

Clearing the screen in 3 seconds...

EOF
sleep 3
clear

cat <<EOF

${BOLD}We will now perform a speech test using FeedDeLingo (free).${RESET}

FeedDeLingo is an AI-powered RSS feed reader designed for language learning.
It allows you to follow news from around the world in any language.
We will use its playback feature to verify that multi-language audio is working correctly.

Once FeedDeLingo loads:
${BOLD}
1. A list of test feeds will appear. Click "Import Selected Feeds" to proceed.
2. Select a news site in a ${REV}language foreign to you${REV_END}.
3. Choose an article that interests you. (If AI analysis is blocked, please try a different article.)
4. When "Read with AI Assist" appears, click it to open the text-to-speech view.
${RESET}
NOTE:
- Loading may take a moment while AI processes the content.
- The "Read with AI Assist" button will not appear for sites in your native language. ${REV}Please ensure you select a foreign language site.${REV_END}

EOF

if ! yesno "Ready to open the test page?"; then
    echo "Skipping browser test."
    exit 1
fi

# NOTE: A browser restart is required to ensure a reliable connection with speech-dispatcher.
if [ "$browser" = "firefox" ]; then
    while pgrep -u "$USER" -x "firefox|firefox-esr|firefox-bin" >/dev/null 2>&1; do
	cat <<EOF

${BOLD}Firefox must be restarted to ensure a reliable connection with Speech Dispatcher.
Please manually close ALL running instances of firefox.${RESET}

EOF
	read -p "Have you closed ALL firefox instances? (Press Enter to continue) " choice
    done
    
    echo "Launching the browser, please wait..."
    $browser "$FL_URL/#/?add-feeds=$FEEDS" >/dev/null 2>&1 &
    disown
else
    while pgrep -u "$USER" -x chromium >/dev/null 2>&1; do
	cat <<EOF

${BOLD}We need to restart Chromium with the --enable-speech-dispatcher flag.
Please manually close ALL running instances of Chromium.${RESET}

EOF
	read -p "Have you closed ALL Chromium instances? (Press Enter to continue) " choice
    done

    echo "Launching the browser, please wait..."
    $browser --enable-speech-dispatcher "$FL_URL/#/?add-feeds=$FEEDS" >/dev/null 2>&1 &
    disown
fi

sleep 20
cat <<EOF

The setup script has finished. We hope the browser test is successful!

EOF
