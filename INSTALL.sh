#!/bin/bash

TIMESTAMP=$(date +"%Y_%m%d"_%H%M)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
EDGETTS_DIR=~/edge-tts
CONFIG_DIR=~/.config/speech-dispatcher
FL_URL="https://feedlingo.yagiful.com"

#

new_dir(){
    local dir="$1"
    
    if [ -d "$dir" ]; then
        echo "Warning: Directory '$dir' already exists."
        local choice
        read -p "Choose an action: [s]kip or [b]ackup? (s/b): " choice
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

cat <<EOF

EDGE-TTS-LINUX-BROWSER

This script enables edge-tts as a backend for the Web Speech API in Linux browsers.
1. ${EDGETTS_DIR}: Install edge-tts and the speech-dispatcher wrapper script.
2. ${CONFIG_DIR}: Configure speech-dispatcher to use the wrapper.
3. Terminal Test: Verify the configuration within your terminal.
4. Browser Launch: Start the browser with the required flags and verify the setup using FeedDeLingo, an AI-powered language learning app.

Step 4 is optional and can be skipped.

$(tput bold)Before proceeding, please ensure that speech-dispatcher and mpg123 are installed.$(tput sgr0)
You can install them using: sudo apt update && sudo apt install speech-dispatcher mpg123

EOF
read -p "Do you want to start the installation? (y/n): " choice
if [ "$choice" != "y" -a "$choice" != "Y" ]; then
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
    echo "Warning: This script is intended for Raspberry Pi OS 13 (Trixie)."
    read -p "OS mismatch detected. The script may work on other Linux distributions, but it is untested. Do you want to continue anyway? (y/n): " choice
    case "$choice" in
        [yY]* )
            echo "Continuing installation..."
            ;;
        * )
            echo "Installation aborted."
            exit 1
            ;;
    esac
fi 

if ! command -v speech-dispatcher >/dev/null; then
    echo "Error: speech-dispatcher not found. Install via: sudo apt update; sudo apt install speech-dispatcher"
    exit 1
fi

if ! command -v mpg123 >/dev/null; then
    echo "Error: mpg123 not found. Install via: sudo apt update; sudo apt install mpg123"
    exit 1
fi

#

if new_dir "$EDGETTS_DIR"; then
    echo "# $EDGETTS_DIR: Installing edge-tts and the wrapper script 'edge-tts-dispatch'"
    cd "$EDGETTS_DIR"
    python -m venv venv
    source venv/bin/activate
    pip install edge-tts
    deactivate
    cp -pr "$SCRIPT_DIR/edge-tts-dispatch" .
    chmod +x edge-tts-dispatch
fi

if new_dir "$CONFIG_DIR"; then
    echo "# $CONFIG_DIR: Configuring speech-dispatcher"
    cd "$CONFIG_DIR"
    cp -pr "$SCRIPT_DIR/speech-dispatcher"/* .
fi

#

cat <<EOF

# Testing configuration in the terminal...

EOF
read -p "(Press Enter to start the test) " choice
echo "Reading aloud short English phrases using the command-line tool (spd-say)."
spd-say -l en "This is a test of edge tts using speech dispatcher." -w
read -p "Did you hear the edge-tts voice? (y/n): " choice
if [ "$choice" != "y" -a "$choice" != "Y" ]; then
    cat <<EOF

Configuration failed.

To uninstall, please remove the following directories:
- ${EDGETTS_DIR}
- ${CONFIG_DIR}

EOF
    exit 1
fi

#

if command -v "chromium-browser" >/dev/null; then
    browser="chromium-browser"
elif command -v "chromium" >/dev/null; then
    browser="chromium"
elif command -v "google-chrome" >/dev/null; then
    browser="google-chrome"
elif command -v "firefox" >/dev/null; then
    browser="firefox"
else
    browser="unknown"
fi

FEEDS="%7B%22version%22%3A1%2C%22feeds%22%3A%5B%7B%22url%22%3A%22https%3A%2F%2Fnews.yahoo.com%2Frss%2Fworld%22%2C%22name%22%3A%22EN%3A%20Yahoo%20News%20-%20Latest%20News%20%26%20Headlines%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.elpais.com%2Fmrss-s%2Fpages%2Fep%2Fsite%2Felpais.com%2Fportada%22%2C%22name%22%3A%22ES%3A%20EL%20PA%C3%8DS%3A%20el%20peri%C3%B3dico%20global%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.bhaskar.com%2Frss-v1--category-1061.xml%22%2C%22name%22%3A%22HI%3A%20Dainik%20Bhaskar%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fwww.tagesschau.de%2Fxml%2Frss2%2F%22%2C%22name%22%3A%22DE%3A%20tagesschau.de%20-%20Die%20Nachrichten%20der%20ARD%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fnews.livedoor.com%2Ftopics%2Frss%2Ftop.xml%22%2C%22name%22%3A%22JA%3A%20Livedoor%20News%20(News%20Aggregation%20Site)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fhnrss.org%2Fbest%22%2C%22name%22%3A%22EN%3A%20Hacker%20News%3A%20Best%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Ffeeds.arstechnica.com%2Farstechnica%2Findex%22%2C%22name%22%3A%22EN%3A%20Ars%20Technica%20-%20All%20content%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Frocketnews24.com%2Ffeed%2F%22%2C%22name%22%3A%22JA%3A%20RocketNews24%20(Quirky%20Japan%20News)%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fsoranews24.com%2Ffeed%2F%22%2C%22name%22%3A%22EN%3A%20SoraNews24%20%20-%20the%20English-language%20sister%20site%20of%20RocketNews24%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%2C%7B%22url%22%3A%22https%3A%2F%2Fanimeanime.jp%2Frss20%2Findex.rdf%22%2C%22name%22%3A%22JA%3A%20Anime!%20Anime!%22%2C%22summarizeContent%22%3Atrue%2C%22summaryLevel%22%3A2%7D%5D%7D"

case "$browser" in
    unknown)
        cat <<EOF

$(tput bold)----------------------------------------------------------------------
Setup completed successfully.

Could not detect a supported browser. Skipping the browser test.
----------------------------------------------------------------------$(tput sgr0)
EOF
        exit 1
	;;
    firefox)
        cat <<EOF

$(tput bold)----------------------------------------------------------------------
Setup completed successfully.
----------------------------------------------------------------------$(tput sgr0)
EOF
        ;;
    google-chrome)
        cat <<EOF

$(tput bold)----------------------------------------------------------------------
Setup completed successfully.

google-chrome might not need the --enable-speech-dispatcher flag, but we will launch it with the flag for the browser test.
----------------------------------------------------------------------$(tput sgr0)
EOF
        ;;
    *)
        cat <<EOF

$(tput bold)----------------------------------------------------------------------
Setup completed successfully.

Please note that to use edge-tts with Chromium, you must launch the browser with the following flag:

$browser --enable-speech-dispatcher 

For instructions on how to make this setting permanent, please see README.md.
----------------------------------------------------------------------$(tput sgr0)
EOF
        ;;
esac

cat <<EOF

# Final Step: Browser Integration Test

Detected browser: $browser

This test will launch '$browser' with the required flags and open FeedDeLingo, an AI-powered
language learning web app, to confirm that edge-tts is working correctly.

EOF

read -p "Do you want to run this browser test? (y/n): " choice
if [ "$choice" != "y" -a "$choice" != "Y" ]; then
        echo "Skipping test."
        exit 0
fi

if [ "$browser" != "firefox" ]; then
    while pgrep -u "$USER" -x chromium >/dev/null \
	    || pgrep -u "$USER" -x google-chrome >/dev/null; do
	cat <<EOF

We need to restart Chromium with the --enable-speech-dispatcher flag.
Please manually close all running instances of Chromium.

EOF
	read -p "Have you closed all Chromium instances? (Press Enter to continue) " choice
    done
fi

cat <<EOF

----------------------------------------------------------------------
FeedDeLingo is an AI-powered RSS feed reader designed for language learning.
You can follow news sites from around the world to learn any language you choose.

Once FeedDeLingo loads:

1. It will offer to import some test feeds. Click "Import Selected Feeds" to continue.
2. Click on a news site in a language that is $(tput bold)foreign to you$(tput sgr0).
3. Click on any article from the list.
4. When "Read with AI Assist" appears, click it to open the text-to-speech view.

NOTE:
- Loading may take a moment while AI processes the content.
$(tput bold)- The "Read with AI Assist" button will not appear for articles in your native language.$(tput sgr0)
----------------------------------------------------------------------

EOF

read -p "Ready to open the test page? (y/n): " choice
if [ "$choice" != "y" -a "$choice" != "Y" ]; then
        echo "Skipping test."
        exit 0
fi

echo "Launching the browser, please wait..."
if [ "$browser" = "firefox" ]; then
    $browser "$FL_URL/#/?add-feeds=$FEEDS" >/dev/null 2>&1 &
    disown
else
    $browser --enable-speech-dispatcher "$FL_URL/#/?add-feeds=$FEEDS" >/dev/null 2>&1 &
    disown
fi

sleep 20
echo "This script will now exit. We hope your test will be successful!"
