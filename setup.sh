#!/bin/bash

set -e

# Enable dpgk kernel update script
echo "Enabling dpkg kernel update script..."
cp ./mark2-hardware/dpkg-vocalfusiondriver-update.sh /etc/kernel/postinst.d/99-dpkg-vocalfusiondriver-update.sh
chmod 0755 /etc/kernel/postinst.d/99-dpkg-vocalfusiondriver-update.sh


# run dpkg kernel update script
/etc/kernel/postinst.d/99-dpkg-vocalfusiondriver-update.sh

# Copying SJ201 firmware and scripts
echo "Copying SJ201 firmware and scripts..."
mkdir -p /opt/mark2-hardware
mkdir -p /opt/mark2-hardware/sj201
cp ./mark2-hardware/sj201/xvf3510-flash.py /opt/mark2-hardware/sj201/xvf3510-flash.py
cp ./mark2-hardware/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin /opt/mark2-hardware/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin
cp ./mark2-hardware/sj201/init_tas5806.py /opt/mark2-hardware/sj201/init_tas5806.py
chmod 0755 /opt/mark2-hardware/sj201/*

# Enable mark2-sj201 systemd unit
echo "Copying mark2-sj201 systemd unit file..."
cp ./mark2-hardware/mark2-sj201.service /etc/systemd/system/mark2-sj201.service
cp ./mark2-hardware/mark2-sj201.sh /opt/mark2-hardware/mark2-sj201.sh
chmod 0755 /opt/mark2-hardware/mark2-sj201.sh
chmod 0644 /etc/systemd/system/mark2-sj201.service

# Enable mark2-sj201 systemd unit
echo "Enabling mark2-sj201 systemd unit..."
systemctl daemon-reload
systemctl enable mark2-sj201.service
systemctl start mark2-hardware.service

# Finish
echo "Setup for Mark II hardware on Raspbian complete. Please reboot the system."
echo "After reboot, you can check the status of the mark2-sj201 service by running 'systemctl status mark2-sj201.service'."
