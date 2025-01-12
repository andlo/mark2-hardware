# Mark2 hardware setup for Raspberry Pi OS 

Welcome to the Mark2 hardware Setup for Raspberry Pi OS. This document will help you get started with setting up Mark2 hardware on your Raspberry Pi OS.

## Installation

To install hrdware drivers on Mark2, follow these steps:

1. **Clone the Mark2 repository:**
    ```sh
    git clone https://github.com/andlo/mark2-hardware.git
    cd mark2
    ```

2. **Run the setup script:**
    ```sh
    sudo ./setup.sh
    ```

## Usage

This setupscript has installed a service mark2-hardware.service which runs on every boot and perorms these tasks:
* If kernelversion has changed, it recompiled new drivers and install these
* Flash the sj201    

## License

missing at the moment 

## Contact

If you have any questions or need further assistance, please open an issue on the [GitHub repository](https://github.com/andlo/mark2-hardware/issues).


