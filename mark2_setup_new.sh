#!/bin/bash

set -e

# Variables
OVOS_HARDWARE_MARK2_VOCALFUSION_REPO_URL="https://github.com/OpenVoiceOS/VocalFusionDriver.git"
OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH="/home/$USER/VocalFusionDriver"
OVOS_HARDWARE_MARK2_VOCALFUSION_BRANCH="main"
BOOT_DIRECTORY="/boot"
ANSIBLE_KERNEL=$(uname -r)
ANSIBLE_PROCESSOR_COUNT=$(nproc)
VENV_PATH="/home/$USER/.venvs/sj201"

# Update and install necessary packages
#echo "Updating and installing necessary packages..."
sudo apt-get update
sudo apt-get install -y git cmake build-essential raspberrypi-kernel-headers jq 


# Create and activate Python virtual environment
echo "Creating and activating Python virtual environment..."
python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"

# Install necessary Python packages in virtual environment
echo "Installing necessary Python packages in virtual environment..."
pip install Adafruit-Blinka smbus2 RPi.GPIO gpiod

mkdir -p /home/$USER/.config/systemd/user

# Update EEPROM
sudo rpi-eeprom-update -a

# Download SJ201 firmware and scripts
echo "Downloading SJ201 firmware and scripts..."
sudo mkdir -p /opt/sj201
sudo curl -L -o /opt/sj201/xvf3510-flash "https://raw.githubusercontent.com/OpenVoiceOS/ovos-buildroot/0e464466194f58553af11c34f7435dba76ec70a3/buildroot-external/package/vocalfusion/xvf3510-flash"
sudo curl -L -o /opt/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin "https://raw.githubusercontent.com/OpenVoiceOS/ovos-buildroot/c67d7f0b7f2a3eff5faab96d6adf7495e9b48b93/buildroot-external/package/vocalfusion/app_xvf3510_int_spi_boot_v4_2_0.bin"
sudo curl -L -o /opt/sj201/init_tas5806 "https://raw.githubusercontent.com/MycroftAI/mark-ii-hardware-testing/main/utils/init_tas5806.py"
sudo chmod 0755 /opt/sj201/*

# Create SJ201 systemd unit file
echo "Copying SJ201 systemd unit file..."
cat <<EOF | tee /home/ovos/.config/systemd/user/sj201.service > /dev/null
[Unit]
Documentation=https://github.com/MycroftAI/mark-ii-hardware-testing/blob/main/README.md
Description=SJ201 microphone initialization
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=%h/.venvs/sj201
ExecStartPre=/usr/bin/sudo rpi-eeprom-update -a
ExecStart=/usr/bin/sudo -E env PATH=$PATH %h/.venvs/sj201/bin/python /opt/sj201/xvf3510-flash --direct /opt/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin --verbose
ExecStartPost=%h/.venvs/sj201/bin/python /opt/sj201/init_tas5806
Restart=on-failure
RestartSec=5s
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF

# Enable and start SJ201 systemd unit
echo "Enabling SJ201 systemd unit..."
systemctl --user daemon-reload
systemctl --user enable sj201.service
#systemctl --user start sj201.service


# Enable and start compile_vocalfussion systemd unit
echo "Copying compile_vocalfusion systemd unit file..."
cat <<EOF | tee /home/ovos/.config/systemd/user/compile_vocalfusion.service > /dev/null
[Unit]
Description=Compile VocalFusionDriver if Kernel has Changed
After=network.target

[Service]
ExecStart=/opt/compile_vocalfusion.sh
User=ovos

[Install]
WantedBy=multi-user.target
EOF

copy compile_vocalfusion.sh /opt/compile_vocalfusion.sh
chmod +x /opt/compile_vocalfusion.sh

cp compile_vocalfusion.service /home/$USER/.config/systemd/user/compile_vocalfusion.service

echo "Enabling compile_vocalfussion systemd unit..."
systemctl --user daemon-reload
systemctl --user enable compile_vocalfusion.service
#systemctl --user start compile_vocalfusion.service


# Setup PipeWire
echo "Setting up PipeWire..."

mkdir -p /home/$USER/.config/wireplumber/
cp 50-alsa-config.lua /home/$USER/.config/wireplumber/50-alsa-config.lua
chmod 0644 /home/$USER/.config/wireplumber/50-alsa-config.lua

systemctl --user enable wireplumber.service
systemctl --user start wireplumber.service
systemctl --user enable pipewire pipewire-pulse
#systemctl --user start pipewire pipewire-pulse


# Test and configure sound
echo "Testing and configuring sound..."
aplay -l
arecord -l

# Delete source path once compiled
echo "Deleting source path once compiled..."
sudo rm -rf "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH"

echo "Setup for Mark II hardware on Raspbian Bookworm Lite with PipeWire completed."

