#!/bin/bash


# Variables
REPO_URL="https://github.com/OpenVoiceOS/VocalFusionDriver.git"
#SRC_PATH="/home/$USER/VocalFusionDriver"
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
    sudo cp vocalfusion-soundcard.ko "/lib/modules/$KERNEL_VERSION/vocalfusion-soundcard.ko"
    sudo depmod

    # Copy DTBO files to /boot/overlays
    echo "Copying DTBO files to /boot/overlays..."
    IS_RPI5=""
    if grep -q "Raspberry Pi 5" /proc/device-tree/model; then
    IS_RPI5="-pi5"
    fi

    for DTBO_FILE in sj201 sj201-buttons-overlay sj201-rev10-pwm-fan-overlay; do
    sudo cp "$OVOS_HARDWARE_MARK2_VOCALFUSION_SRC_PATH/$DTBO_FILE$IS_RPI5.dtbo" "$BOOT_DIRECTORY/overlays/"
    done

    # Manage overlays in /boot/config.txt
    echo "Managing overlays in /boot/config.txt..."
    for DTO_OVERLAY in sj201 sj201-buttons-overlay sj201-rev10-pwm-fan-overlay; do
    if ! grep -q "^dtoverlay=$DTO_OVERLAY$IS_RPI5" "$BOOT_DIRECTORY/firmware/config.txt"; then
        echo "dtoverlay=$DTO_OVERLAY$IS_RPI5" | sudo tee -a "$BOOT_DIRECTORY/firmware/config.txt"
    fi
    done

    # Update the last kernel version file
    echo "$KERNEL_VERSION" > "$LAST_KERNEL_VERSION_FILE"

    echo "VocalFusionDriver compiled successfully. Rebooting system..."
    sudo reboot
else
    echo "Kernel version has not changed. No need to compile."
fi
