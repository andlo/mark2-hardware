#!/bin/bash

set -e

# Update and install necessary packages
echo "Updating and installing necessary packages..."
apt-get update
apt-get install -y git cmake build-essential raspberrypi-kernel-headers jq python3-dev

# Enable I2C interface
echo "Enabling I2C interface..."
raspi-config nonint do_i2c 0

# Update EEPROM
rpi-eeprom-update -a

# Create and activate Python virtual environment
echo "Creating and activating Python virtual environment..."
mkdir -p /opt/mark2-hardware
mkdir -p /opt/mark2-hardware/sj201
chomon -R 0755 /opt/mark2-hardware
chmod 0755 /opt/mark2-hardware/sj201
python3 -m venv "/opt/mark2-hardware/sj201"
source "/opt/mark2-hardware/sj201/bin/activate"

# Install necessary Python packages in virtual environment
echo "Installing necessary Python packages in virtual environment..."
pip install --upgrade pip
pip install Adafruit-Blinka smbus2 RPi.GPIO gpiod

# Copying SJ201 firmware and scripts
echo "Copying SJ201 firmware and scripts..."
cp mark2-hardware/sj201/xvf3510-flash /opt/mark2-hardware/sj201/xvf3510-flash
cp mark2-hardware/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin /opt/mark2-hardware/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin
cp mark2-hardware/sj201/init_tas5806.py /opt/mark2-hardware/sj201/init_tas5806.py
chmod 0755 /opt/mark2-hardware/sj201/*

# Enable mark2-hardware systemd unit
echo "Copying mark2-hardware systemd unit file..."
cp mark2-hardware/mark2-hardware.service /etc/systemd/system/mark2-hardware.service
chmod 0644 /etc/systemd/system/mark2-hardware.service

# Enable mark2-hardware systemd unit
echo "Enabling mark2-hardware systemd unit..."
systemctl daemon-reload
systemctl enable mark2-hardware.service
#systemctl --user start mark2-hardware.service

# Test and configure sound
echo "Testing and configuring sound..."
aplay -l
arecord -l

# Finish
echo "Setup for Mark II hardware on Raspbian complete. Please reboot the system."

