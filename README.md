# EDGE-TTS-LINUX-BROWSER

Transform your Linux browser's text-to-speech from robotic to natural. This project integrates Microsoft Edge's high-quality, neural TTS voices directly into your web browser using `edge-tts` and `speech-dispatcher`.

### How It Works
Modern browsers use the **Web Speech API** for text-to-speech. On Linux, this API typically communicates with **Speech Dispatcher**.
This project acts as a bridge:
`Browser` → `Speech Dispatcher` → `Custom Wrapper Script` → `edge-tts (Neural Cloud Voices)`

### Features
- **Natural Voices:** Access Microsoft Edge's neural TTS engines (multilingual).
- **Seamless Integration:** Works with any website using the standard Web Speech API.
- **One-Step Setup:** Automated configuration for Raspberry Pi OS and other Debian-based distros.

Tested on Raspberry Pi OS Trixie (Debian 13), but it should work on many other Linux distributions.

> [!IMPORTANT]
> This setup works best with native packages (`.deb`). Browsers installed via **Snap** or **Flatpak** may have sandbox restrictions that prevent communication with Speech Dispatcher.

## Installation

For a quick, one-line installation, run the following command:
```bash
curl -sSfL https://raw.githubusercontent.com/onitenjikunezumi/edge-tts-linux-browser/main/.github/install.sh | bash
```

If you prefer to inspect the project files before installing, follow these steps:

1. Clone this repository somewhere in your home directory.
   ```bash
   git clone https://github.com/onitenjikunezumi/edge-tts-linux-browser.git
   ```
2. Navigate to the cloned directory.
   ```bash
   cd edge-tts-linux-browser
   ```
3. Run the setup script:
   ```bash
   bash ./setup.sh
   ```
   
### Installed Files and Directories

- **~/.local/share/edge-tts-linux-browser:** edge-tts core and speech-dispatcher wrapper scripts.
- **~/.config/speech-dispatcher:** speech-dispatcher configuration files.

### Required Packages

The installation script will check for and help you install the following dependencies:

- python3, python3-venv
- speech-dispatcher
- mpg123

## Usage
Once installed, your browser will have access to new "Edge" voices.
1. Restart your browser (following the Chromium instructions below if applicable).
2. Open any site that supports text-to-speech.
3. Select an Edge voice from the site's voice settings.

To verify your installation, we recommend testing with **FeedDeLingo**, an AI-powered language learning app that utilizes multi-language synthesis. This test is conveniently integrated into the `setup.sh` script, which automatically handles tedious tasks like launching your browser with the required flags.

## Configuring Chromium

Chromium does not enable `speech-dispatcher` support by default. **Therefore, to use the text-to-speech capabilities configured by this project, you must launch Chromium with a specific flag.**

### Manual Launch

1. If Chromium is already running, please close all instances completely before proceeding.

2. Open a terminal and run the following command:
   ```bash
   chromium-browser --enable-speech-dispatcher
   ```

### Permanent Configuration

To avoid typing the flag every time, you can add it to the Chromium configuration file:

1. Open the configuration file with root privileges:
   ```bash
   sudo nano /etc/chromium.d/10-speech-dispatcher
   ```
2. Add the following line to the file:
   ```bash
   export CHROMIUM_FLAGS="$CHROMIUM_FLAGS --enable-speech-dispatcher"
   ```

## Firefox

In Firefox, `speech-dispatcher` is enabled by default, so no special configuration is required.

## Customization

You can change the default voices or speech parameters by editing the configuration files in:
`~/.config/speech-dispatcher/modules/edge-tts.conf` or by modifying the wrapper scripts in `~/.local/share/edge-tts-linux-browser`.

## Uninstallation

To uninstall, you need to remove the files and directories created during setup.

1.  Remove the `edge-tts` installation and `speech-dispatcher` configuration directories from your home folder:
    ```bash
    rm -rf ~/.local/share/edge-tts-linux-browser ~/.config/speech-dispatcher
    ```

2.  If you created the permanent configuration for Chromium, remove the system file as well (this requires root privileges):
    ```bash
    sudo rm /etc/chromium.d/10-speech-dispatcher
    ```
