#!/bin/bash

# Variables
REPO_URL="https://github.com/OpenVoiceOS/VocalFusionDriver.git"
SRC_PATH="/opt/VocalFusionDriver"
KERNEL_VERSION=$(uname -r)
LAST_KERNEL_VERSION_FILE="/opt/last_kernel_version"

# Create last kernel version file if it doesn't exist
if [ ! -f "$LAST_KERNEL_VERSION_FILE" ]; then
    echo "" > "$LAST_KERNEL_VERSION_FILE"
fi

# Read last kernel version
LAST_KERNEL_VERSION=$(cat "$LAST_KERNEL_VERSION_FILE")

# Check if kernel version has changed
if [ "$KERNEL_VERSION" != "$LAST_KERNEL_VERSION" ]; then
    echo "Kernel version has changed. Compiling VocalFusionDriver..."

    # Clone the repository if it doesn't exist
    if [ ! -d "$SRC_PATH" ]; then
        git clone "$REPO_URL" "$SRC_PATH"
    else
        # Update the repository if it already exists
        cd "$SRC_PATH"
        git pull
    fi

    # Build the driver
    cd "$SRC_PATH/driver"
    make clean
    make -j$(nproc) KDIR="/lib/modules/$KERNEL_VERSION/build"

    # Copy the compiled module
    cp vocalfusion-soundcard.ko "/lib/modules/$KERNEL_VERSION/vocalfusion-soundcard.ko"
    depmod -a

    # Copy DTBO files to /boot/overlays
    echo "Copying DTBO files to /boot/overlays..."
    IS_RPI5=""
    if grep -q "Raspberry Pi 5" /proc/device-tree/model; then
    IS_RPI5="-pi5"
    fi

    for DTBO_FILE in sj201 sj201-buttons-overlay sj201-rev10-pwm-fan-overlay; do
    cp "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH/$DTBO_FILE$IS_RPI5.dtbo" "$BOOT_DIRECTORY/overlays/"
    done

    # Manage overlays in /boot/config.txt
    echo "Managing overlays in /boot/config.txt..."
    for DTO_OVERLAY in sj201 sj201-buttons-overlay sj201-rev10-pwm-fan-overlay; do
    if ! grep -q "^dtoverlay=$DTO_OVERLAY$IS_RPI5" "$BOOT_DIRECTORY/firmware/config.txt"; then
        echo "dtoverlay=$DTO_OVERLAY$IS_RPI5" | tee -a "$BOOT_DIRECTORY/firmware/config.txt"
    fi
    done
    
    # Create /etc/modules-load.d/vocalfusion.conf file
    echo "Creating /etc/modules-load.d/vocalfusion.conf..."
    echo "vocalfusion-soundcard" | tee /etc/modules-load.d/vocalfusion.conf > /dev/null
    chmod 0644 /etc/modules-load.d/vocalfusion.conf

    # Update the last kernel version file
    echo "$KERNEL_VERSION" > "$LAST_KERNEL_VERSION_FILE"

    echo "VocalFusionDriver compiled successfully. Rebooting system..."
    reboot
else
    echo "Kernel version has not changed. No need to compile."
fi

# update the eeprom 
/usr/bin/rpi-eeprom-update -a

# Flash the xvf3510
echo "Flashing xvf3510..."
/opt/sj201/bin/python /mark2-hardware/opt/sj201/xvf3510-flash --direct /opt/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin --verbose
/opt/sj201/bin/python /mark2-hardware/opt/sj201/init_tas5806.py