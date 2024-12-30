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
#sudo apt-get update
#sudo apt-get install -y git cmake build-essential raspberrypi-kernel-headers wireplumber pipewire pipewire-alsa pipewire-pulse jq python3-pip python3-venv

# Clone VocalFusionDriver Git repository
echo "Cloning VocalFusionDriver Git repository..."
git clone -b "$OVOS_HARDWARE_MARK2_VOCALFUSION_BRANCH" "$OVOS_HARDWARE_MARK2_VOCALFUSION_REPO_URL" "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH"

# Copy DTBO files to /boot/overlays
echo "Copying DTBO files to /boot/overlays..."
IS_RPI5=""
if grep -q "Raspberry Pi 5" /proc/device-tree/model; then
  IS_RPI5="-pi5"
fi

for DTBO_FILE in sj201 sj201-buttons-overlay sj201-rev10-pwm-fan-overlay; do
  sudo cp "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH/$DTBO_FILE$IS_RPI5.dtbo" "$BOOT_DIRECTORY/overlays/"
  sudo chmod 0755 "$BOOT_DIRECTORY/overlays/$DTBO_FILE$IS_RPI5.dtbo"
done

# Manage overlays in /boot/config.txt
echo "Managing overlays in /boot/config.txt..."
for DTO_OVERLAY in sj201 sj201-buttons-overlay sj201-rev10-pwm-fan-overlay; do
  if ! grep -q "^dtoverlay=$DTO_OVERLAY$IS_RPI5" "$BOOT_DIRECTORY/firmware/config.txt"; then
    echo "dtoverlay=$DTO_OVERLAY$IS_RPI5" | sudo tee -a "$BOOT_DIRECTORY/firmware/config.txt"
  fi
done

# Build vocalfusion-soundcard.ko kernel module
echo "Building vocalfusion-soundcard.ko kernel module..."
cd "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH/driver"
make -j "$ANSIBLE_PROCESSOR_COUNT" KDIR="/lib/modules/$ANSIBLE_KERNEL/build" all

# Copy vocalfusion-soundcard.ko to /lib/modules
echo "Copying vocalfusion-soundcard.ko to /lib/modules..."
sudo cp "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH/driver/vocalfusion-soundcard.ko" "/lib/modules/$ANSIBLE_KERNEL/vocalfusion-soundcard.ko"
sudo chmod 0644 "/lib/modules/$ANSIBLE_KERNEL/vocalfusion-soundcard.ko"
sudo depmod

# Create /etc/modules-load.d/vocalfusion.conf file
echo "Creating /etc/modules-load.d/vocalfusion.conf..."
echo "vocalfusion-soundcard" | sudo tee /etc/modules-load.d/vocalfusion.conf > /dev/null
sudo chmod 0644 /etc/modules-load.d/vocalfusion.conf

# Create and activate Python virtual environment
echo "Creating and activating Python virtual environment..."
python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"

# Install necessary Python packages in virtual environment
echo "Installing necessary Python packages in virtual environment..."
pip install Adafruit-Blinka smbus2 RPi.GPIO gpiod

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
[Unit]
Documentation=https://github.com/MycroftAI/mark-ii-hardware-testing/blob/main/README.md
Description=SJ201 microphone initialization
After=network-online.target

[Service]
Type=oneshot
WorkingDirectory=%h/.venvs/sj201
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
systemctl --user start sj201.service

# Setup PipeWire
echo "Setting up PipeWire..."
systemctl --user enable wireplumber.service
systemctl --user start wireplumber.service
systemctl --user enable pipewire pipewire-pulse
systemctl --user start pipewire pipewire-pulse


# Test and configure sound
echo "Testing and configuring sound..."
aplay -l
arecord -l

# Delete source path once compiled
echo "Deleting source path once compiled..."
sudo rm -rf "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH"

echo "Setup for Mark II hardware on Raspbian Bookworm Lite with PipeWire completed."

