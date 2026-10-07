#!/usr/bin/env bash
#
# Project:     EDGE-TTS-LINUX-BROWSER
# Description: Installation script for edge-tts and speech-dispatcher integration.
# Author:      onitenjikunezumi
# Repository:  https://github.com/onitenjikunezumi/edge-tts-linux-browser
#

set -euo pipefail

exec < /dev/tty

TIMESTAMP=$(date +"%Y_%m%d"_%H%M)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
EDGETTS_DIR=~/.local/share/edge-tts-linux-browser
CONFIG_DIR=~/.config/speech-dispatcher
FL_URL="https://feedlingo.yagiful.com"

#

BOLD=$'\033[1m'
RESET=$'\033[0m'

bold(){
    sed "s/\*\*\([^*]*\)\*\*/${BOLD}\1${RESET}/g"
}

mk(){
    local line
    while IFS= read -r line; do
        case "$line" in
            \#*\ *) echo "**$line**" | bold ;;
            *) echo "$line" | bold ;;
        esac
    done
}

confirm(){
    local choice
    read -p "$BOLD> $1 (Press Enter)$RESET" choice
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

abort(){
    echo "**${1}**" | bold 
    exit 
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

kill_speech_dispatcher(){
    if [ -z "${kill_speech_dispatcher_flag:-}" ]; then
        echo "Stopping existing speech-dispatcher processes..."
        pkill -u "$USER" -x speech-dispatcher >/dev/null 2>&1 || true    
        sleep 2
        kill_speech_dispatcher_flag=1
    fi
}

uninstall_instruction(){
    cat <<EOF | mk
**To uninstall the installed files, please remove the following directories:**
- ${EDGETTS_DIR}
- ${CONFIG_DIR}

EOF
}
    
#

cat <<EOF | mk

# EDGE-TTS-LINUX-BROWSER

This script integrates edge-tts to enable high-quality text-to-speech in multiple languages on Linux, and configures it to work with Chromium and Firefox.

**Components to install:**
- edge-tts
- speech-dispatcher

**Installation steps:**
1. Install edge-tts and speech-dispatcher integration files (${EDGETTS_DIR})
2. Configure speech-dispatcher (${CONFIG_DIR})
3. Test speech synthesis in the terminal
4. Test speech synthesis in the browser

**Disclaimer:**
This script is provided "as is" without warranty of any kind, either expressed or implied. The author is not responsible for any damage or loss of data that may result from the use of this script. By using this script, you agree to assume all risks associated with its use.

EOF

yesno "Do you want to continue?" || abort "Aborting installation."

#

IS_RPI=1
if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model; then
    IS_RPI=0
fi

IS_UBUNTU=1
if [ -f /etc/os-release ] && grep -q "ID=ubuntu" /etc/os-release; then
    IS_UBUNTU=0
fi

IS_TRIXIE=1
if [ -f /etc/os-release ] && grep -q "VERSION_CODENAME=trixie" /etc/os-release; then
    IS_TRIXIE=0
fi

if [ "$IS_RPI" = "0" -a "$IS_TRIXIE" = "0" ]; then
    : # Do nothing
else
cat <<EOF | mk

## Non-Raspberry Pi OS 13 (Trixie) environment detected.

While this may work on other distributions, it has not been fully tested.

- On Ubuntu, both Chromium and Firefox are installed via Snap, which generally makes Text-to-Speech (TTS) difficult to use. However, Firefox has special workarounds in place, so it might be possible to connect.
- If required packages are missing, this script will attempt to install them using **sudo apt**. If you are using a Linux distribution with a different package manager, you may need to install the missing packages manually.

EOF
    yesno "Do you want to continue?" || abort "Installation aborted."
fi 

#

apt_packages=()

if ! command -v python3 >/dev/null 2>&1; then
    apt_packages+=("python3" "python3-venv")
else
    tmp_venv=$(mktemp -d)
    trap 'rm -rf "$tmp_venv"' EXIT
    if ! python3 -m venv "$tmp_venv" >/dev/null 2>&1; then
        apt_packages+=("python3-venv")
    fi
fi

if ! command -v spd-say >/dev/null 2>&1; then
    apt_packages+=("speech-dispatcher")
fi

if ! command -v mpg123 >/dev/null 2>&1; then
    apt_packages+=("mpg123")
fi

if [ "${#apt_packages[@]}" -gt 0 ]; then
    apt_packages_installed=1
    cat <<EOF | mk

## Additional packages required

Missing packages: ${apt_packages[*]}

**Sudo privileges are required for installation.**

EOF
    if command -v apt >/dev/null 2>&1; then    
        if yesno "Would you like to install them now?"; then
            if sudo apt update && sudo apt install -y "${apt_packages[@]}"; then
                apt_packages_installed=0
            else
                echo "Error: Package installation failed. Please check your permissions or network."
            fi
        fi
    else
        echo "Error: 'apt' package manager not found. Other installers are not supported."
    fi

    if [ "$apt_packages_installed" != 0 ]; then
        echo "Please install the required packages manually before running this script again."
        abort "Installation aborted."
    fi
fi

#

cat <<EOF | mk

## 1. Install edge-tts and speech-dispatcher integration files (${EDGETTS_DIR})

EOF

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

cat <<EOF | mk

## 2. Configure speech-dispatcher (${CONFIG_DIR})

EOF

if new_dir "$CONFIG_DIR"; then
    cd "$CONFIG_DIR"
    echo "Copying configuration files..."
    cp -pr "$SCRIPT_DIR/speech-dispatcher"/* .
fi

#

cat <<EOF | mk

## 3. Test speech synthesis in the terminal

Let's check if text-to-speech is working properly in the terminal.

Before running the test, please ensure:
- Standard audio files (like WAV or MP3) can be played on your Linux system.
- Your speaker volume is set to an appropriate level.

EOF
if yesno "Would you like to run the test?"; then
    kill_speech_dispatcher
    echo "Speaking a test phrase using spd-say..."
    spd-say -l en-us "This is a test of Edge-TTS using Speech Dispatcher." -w
    if ! yesno "Did you hear the voice clearly?"; then
        cat <<EOF

## Configuration failed

EOF
        uninstall_instruction
        abort "Exiting."
    fi
else
    echo "Skipping this test."
fi

#

FEEDS="%7B%22version%22%3A1%2C%22feeds%22%3A%5B%7B%22url%22%3A%22http%3A%2F%2Ffeeds.bbci.co.uk%2Fnews%2Fworld%2Frss.xml%22%2C%22name%22%3A%22EN%3A%20BBC%20News%20-%20World%20News%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fnews.yahoo.com%2Frss%2Fworld%22%2C%22name%22%3A%22EN%3A%20Yahoo%20News%20-%20Latest%20News%20%26%20Headlines%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.reforma.com%2Frss%2Fportada.xml%22%2C%22name%22%3A%22ES%3A%20Reforma%20(News)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.elpais.com%2Fmrss-s%2Fpages%2Fep%2Fsite%2Felpais.com%2Fportada%22%2C%22name%22%3A%22ES%3A%20EL%20PA%C3%8DS%3A%20el%20periodico%20global%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.lefigaro.fr%2Frss%2Ffigaro_actualites.xml%22%2C%22name%22%3A%22FR%3A%20Le%20Figaro%20-%20Actualite%20en%20direct%20et%20informations%20en%20continu%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.cms.handelsblatt.com%2Fschlagzeilen%22%2C%22name%22%3A%22DE%3A%20Handelsblatt%20Schlagzeilen%20(News)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.bhaskar.com%2Frss-v1--category-1061.xml%22%2C%22name%22%3A%22HI%3A%20Dainik%20Bhaskar%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fnews.livedoor.com%2Ftopics%2Frss%2Ftop.xml%22%2C%22name%22%3A%22JA%3A%20Livedoor%20News%20(News%20Aggregation%20Site)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fhnrss.org%2Fbest%22%2C%22name%22%3A%22EN%3A%20Hacker%20News%3A%20Best%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.arstechnica.com%2Farstechnica%2Findex%22%2C%22name%22%3A%22EN%3A%20Ars%20Technica%20-%20All%20content%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Frocketnews24.com%2Ffeed%2F%22%2C%22name%22%3A%22JA%3A%20RocketNews24%20(Quirky%20Japan%20News)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fsoranews24.com%2Ffeed%2F%22%2C%22name%22%3A%22EN%3A%20SoraNews24%20%20-%20the%20English-language%20sister%20site%20of%20RocketNews24%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fanimeanime.jp%2Frss20%2Findex.rdf%22%2C%22name%22%3A%22JA%3A%20Anime!%20Anime!%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%5D%7D"

cat <<EOF | mk

## 4. Test speech synthesis in the browser

Let's check if text-to-speech works correctly in your web browser.

EOF
if yesno "Would you like to run this test?"; then
    browser=""
    flag=0
    if [ "$IS_UBUNTU" = "1" ] && command -v "chromium-browser" >/dev/null 2>&1; then
        browser="chromium-browser"
        flag=0
    elif [ "$IS_UBUNTU" = "1" ] && command -v "chromium" >/dev/null 2>&1; then
        browser="chromium"
        flag=0
    elif command -v "firefox" >/dev/null 2>&1; then
        browser="firefox"
        flag=1
    fi

    if [ -n "$browser" ]; then
        if [ "$flag" = 0 ]; then
            # chromium
            cat <<EOF | mk

Detected browser: $browser

**Note: To use text-to-speech in this browser, you must launch it with the following flag:**

$browser --enable-speech-dispatcher

You can also configure it to launch with this flag automatically. Please refer to the **README.md** for details.

EOF
            confirm "Proceed"

	    while pgrep -u "$USER" -x chromium >/dev/null 2>&1; do
cat <<EOF | mk

**Active Chromium instance detected.**

Please close **ALL** running Chromium instances **MANUALLY.**

**Reason:** The tests require Chromium to be launched with the specific flags (--enable-speech-dispatcher), which is not possible when another instance is already running.

EOF
                confirm "Have you closed all Chromium instances?"
            done
        else
            # firefox
            cat <<EOF | mk

Detected browser: $browser

We will now run the test using this browser.

EOF
            confirm "Proceed"
        fi

        cat <<EOF | mk

## Browser Test with FeedDeLingo

FeedDeLingo is an AI-powered RSS feed reader designed for language learning.
It allows you to follow news from around the world in any language.
We will use its playback feature to verify that multi-language audio is working correctly.

**Once FeedDeLingo loads:**
1. A list of test feeds will appear. Click "Import Selected Feeds" to proceed.
2. Select a news site in a **LANGUAGE FOREIGN TO YOU.**
3. Choose an article that interests you. (If AI analysis is blocked, please try a different article.)
4. When "Read with AI Assist" appears, click it to open the text-to-speech view.

EOF
        confirm "Proceed"

        cat <<EOF | mk

This setup script will exit after opening FeedDeLingo in your browser.
We hope your browser test goes smoothly!

**As a reminder:** When using FeedDeLingo, make sure to select a news site in a **LANGUAGE FOREIGN TO YOU.**

EOF
        confirm "Proceed"

        kill_speech_dispatcher
        cat <<EOF | mk

Opening FeedDeLingo in the browser...

EOF
        if [ "$flag" = 0 ]; then
            # chromium
            $browser --enable-speech-dispatcher "$FL_URL/#/?add-feeds=$FEEDS" >/dev/null 2>&1 &
        else
            # firefox
            $browser "$FL_URL/#/?add-feeds=$FEEDS" >/dev/null 2>&1 &
        fi
        disown
        sleep 10
    else
        cat <<EOF | mk
No supported browser detected.
Skipping browser test.
EOF
    fi
fi

#

uninstall_instruction
echo "**Setup script completed.**" | mk
