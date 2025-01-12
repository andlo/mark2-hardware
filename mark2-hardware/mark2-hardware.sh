#!/bin/bash

# Variables
REPO_URL="https://github.com/OpenVoiceOS/VocalFusionDriver.git"
SRC_PATH="/opt/mark2-hardware/VocalFusionDriver"
KERNEL_VERSION=$(uname -r)
LAST_KERNEL_VERSION_FILE="/opt/mark2-hardware/last_kernel_version"
BOOT_DIRECTORY="/boot"

# Create last kernel version file if it doesn't exist
if [ ! -f "$LAST_KERNEL_VERSION_FILE" ]; then
    echo "" > "$LAST_KERNEL_VERSION_FILE"
fi

# Read last kernel version
LAST_KERNEL_VERSION=$(cat "$LAST_KERNEL_VERSION_FILE")

# Check if kernel version has changed
if [ "$KERNEL_VERSION" != "$LAST_KERNEL_VERSION" ]; then
    echo "Kernel version has changed. Compiling VocalFusionDriver..."
    # Update and install necessary packages
    echo "Updating and installing necessary packages..."
    apt-get update
    apt-get install -y git cmake build-essential raspberrypi-kernel-headers jq python3-dev python3-venv python3-pip

    # Enable I2C interface
    echo "Enabling I2C interface..."
    raspi-config nonint do_i2c 0

    # Update EEPROM
    rpi-eeprom-update -a

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
    cp "$SRC_PATH/$DTBO_FILE$IS_RPI5.dtbo" "$BOOT_DIRECTORY/overlays/"
    done

    # Manage overlays in /boot/config.txt
    echo "Managing overlays in /boot/config.txt..."
    for DTO_OVERLAY in sj201 sj201-buttons-overlay sj201-rev10-pwm-fan-overlay; do
    if ! grep -q "^dtoverlay=$DTO_OVERLAY$IS_RPI5" "$BOOT_DIRECTORY/firmware/config.txt"; then
        echo "dtoverlay=$DTO_OVERLAY$IS_RPI5" | tee -a "$BOOT_DIRECTORY/firmware/config.txt"
    fi
    done

    BACKLIGHT_OVERLAY="dtoverlay=rpi-backlight"
    KMS_OVERLAY="dtoverlay=vc4-kms-v3d"
    FKMS_OVERLAY="dtoverlay=vc4-fkms-v3d"
    if grep -q "^$BACKLIGHT_OVERLAY" "$BOOT_DIRECTORY/firmware/config.txt"; then
        echo "$BACKLIGHT_OVERLAY is already present."
    else
        echo "$BACKLIGHT_OVERLAY" | sudo tee -a "$BOOT_DIRECTORY/firmware/config.txt"
    fi

    echo "Managing touchscreen, DevKit vs Mark II..."
    if [[ $(i2cdetect -y 1) == *attiny1614* ]]; then
        echo "Detected 'attiny1614', configuring overlays..."
        sudo sed -i "/^$KMS_OVERLAY/d" "$BOOT_DIRECTORY/firmware/config.txt"  # Remove KMS overlay
        if ! grep -q "^$FKMS_OVERLAY" "$BOOT_DIRECTORY/firmware/config.txt"; then
            echo "$FKMS_OVERLAY" | sudo tee -a "$BOOT_DIRECTORY/firmware/config.txt"  # Add FKMS overlay
        fi
    else
        echo "'attiny1614' not detected, no changes made."
    fi

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

# create and activate python virtual environment
VENV_PATH="/opt/mark2-hardware/sj201"
ACTIVATE_PATH="$VENV_PATH/bin/activate"

if [ ! -f "$ACTIVATE_PATH" ]; then
    echo "Creating and activating Python virtual environment..."

    mkdir -p "$VENV_PATH"
    chmod -R 0755 /opt/mark2-hardware
    python3 -m venv "$VENV_PATH"
    source "$ACTIVATE_PATH"

    echo "Installing necessary Python packages in virtual environment..."
    pip install --upgrade pip
    pip install Adafruit-Blinka smbus2 RPi.GPIO gpiod
else
    echo "Virtual environment already exists at $VENV_PATH"
    source "$ACTIVATE_PATH"

fi

# Flash the xvf3510
echo "Flashing xvf3510..."
/opt/mark2-hardware/sj201/bin/python /opt/mark2-hardware/sj201/xvf3510-flash.py --direct /opt/mark2-hardware/sj201/app_xvf3510_int_spi_boot_v4_2_0.bin --verbose
/opt/mark2-hardware/sj201/bin/python /opt/mark2-hardware/sj201/init_tas5806.py

# Test and configure sound
echo "Testing and configuring sound..."
aplay -l
arecord -l
