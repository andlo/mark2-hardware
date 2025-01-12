# Mark2 hardware setup for Raspberry Pi OS 

Welcome to the Mark2 hardware Setup for Raspberry Pi OS. This document will help you get started with setting up Mark2 hardware on your Raspberry Pi OS.

## Installation

To install hardware drivers on Mark2, follow these steps:

1. **Clone the Mark2 repository:**
    ```sh
    git clone https://github.com/andlo/mark2-hardware.git
    cd mark2-hardware
    ```

2. **Run the setup script:**
    ```sh
    sudo ./setup.sh
    ```

## Usage

This setupscript install the VocalFusionDriver and enables what is needed and add a dpkg hook to automactly compile 
the VocalFusionDriver when kernel is updated.
It also adds a service mark2-sj201.service which runs on every boot and initialise the sj201 microphone

## License

missing at the moment 

## Contact

If you have any questions or need further assistance, please open an issue on the [GitHub repository](https://github.com/andlo/mark2-hardware/issues).


