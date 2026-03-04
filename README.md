# EDGE-TTS-LINUX-BROWSER

The goal of this project is to bring fluent, multilingual speech synthesis to browsers on Linux platforms like Raspberry Pi OS.

To achieve this, we leverage `edge-tts`, a Python library that allows you to use Edge's online text-to-speech service on the desktop. Integrating `edge-tts` with browsers requires configuring `speech-dispatcher`. Our script automates this configuration, allowing you to complete the setup in a single step.

We have also prepared a functional test using FeedDeLingo, an AI-powered language learning web app. You can use its text-to-speech feature to listen to news articles from around the world, allowing you to verify the quality of the multilingual speech synthesis provided by edge-tts.

Tested on Raspberry Pi OS Trixie, but it should work on many other Linux distributions.

## Requirements

You need to install `speech-dispatcher` and `mpg123` beforehand. You can install them using the following commands:

```bash
sudo apt update
sudo apt install speech-dispatcher mpg123
```

## Installation

The installation script sets up `edge-tts` in `~/edge-tts` and configures `~/.config/speech-dispatcher` to use it.

1. Clone this repository somewhere in your home directory.
2. Navigate to the cloned directory.
3. Run the installation script:
   ```bash
   bash ./INSTALL.sh
   ```

After running the script, the setup for `edge-tts` and `speech-dispatcher` will be complete. You will also have the option to test the setup using FeedDeLingo.

## Configuring Chromium

Chromium (not Google Chrome) does not enable `speech-dispatcher` support by default. **Therefore, to use the text-to-speech capabilities configured by this project, you must launch Chromium with a specific flag.**

### Manual Launch
Run the following command in your terminal:
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

## Firefox and other browsers

In Firefox, `speech-dispatcher` is enabled by default, so no special configuration is required.

Other browsers should also work, provided they have support for `speech-dispatcher`.

## Uninstallation

To uninstall, you need to remove the files and directories created during setup.

1.  Remove the `edge-tts` installation and `speech-dispatcher` configuration directories from your home folder:
    ```bash
    rm -rf ~/edge-tts ~/.config/speech-dispatcher
    ```

2.  If you created the permanent configuration for Chromium, remove the system file as well (this requires root privileges):
    ```bash
    sudo rm /etc/chromium.d/10-speech-dispatcher
    ```
