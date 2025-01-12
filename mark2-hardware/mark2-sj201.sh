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
