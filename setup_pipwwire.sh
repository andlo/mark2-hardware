#!/bin/bash
# -----------------------------------------------------------------------------
# 
# DESCRIPTION: 
# This script is used to set up and configure PipeWire on the system. 
# PipeWire is a server for handling multimedia on Linux.
#
# -----------------------------------------------------------------------------
# Setup PipeWire
echo "Setting up PipeWire..."

mkdir -p /home/$USER/.config/wireplumber/
cp mark2-hardware/50-alsa-config.lua /home/$USER/.config/wireplumber/50-alsa-config.lua
chmod 0644 /home/$USER/.config/wireplumber/50-alsa-config.lua

if [ -f ~/.config/systemd/user/wireplumber.service ]; then
    systemctl --user enable wireplumber.service
    systemctl --user start wireplumber.service
else
    echo "wireplumber.service does not exist in ~/.config/systemd/user/"
fi
if [ -f ~/.config/systemd/user/pipewire.service ] && [ -f ~/.config/systemd/user/pipewire-pulse.service ]; then
    systemctl --user enable pipewire pipewire-pulse
    systemctl --user start pipewire pipewire-pulse
else
    echo "pipewire or pipewire-pulse service does not exist in ~/.config/systemd/user/"
fi


# Test and configure sound
echo "Testing and configuring sound..."
aplay -l
arecord -l

# Finish
echo "Setup for PipeWire complete."
