# Klippain-Chocolate

> Klippain-🍫 - The pain-free recipe for (french)bread and butter Klipper configuration! (Now it's better with some chocolate)


Klippain-🍫 is a generic, modular, and highly customizable Klipper configuration for 3D printers. Designed for use on various machines such as Cartesian, CoreXY and CoreXZ, it has been reported working correctly on Voron V2.4, Voron Trident, Voron V0, Voron SwitchWire, TriZero, VZbot, Ender5, Ender3, Prusas, etc...

![Klippain-🍫](./docs/klippain-chocolate.png)

Klippain-Chocolate is regularly updated with new features and merged PRs from users. You can reach me on the Voron Discord as **_elpopo_** or **fboc**.

Fun fact: "pain" \pɛ̃\ is the French word for bread, so there's no pain in this pain—only joy. We decided to add chocolate to make it even more delicious ! Thanks to the French channel "honhonhonbaguette-FR" on the Voron Discord for the joke and name suggestion!


## Features

Klippain-🍫 is designed for versatility. By selecting and enabling the desired hardware and software options, it can be used on a wide range of machines.

Custom features available out of the box include a full featured set of standard macros, **adaptive bed mesh**, **custom printer calibrations**, **automated input shaper workflows**, and **vibration measurement** macros and scripts, ... Refer to the [features documentation](./docs/features.md) for a detailed list and usage instructions.


## Installation

To install Klippain-🍫, first ensure you have already Klipper, Moonraker, and a WebUI installed on your printer. If not, you can use [KIAUH](https://github.com/th33xitus/kiauh).

Then, run the installation script using the following command over SSH. This script will backup your old configuration, download this GitHub repository to your RaspberryPi home directory, and set up Klippain-🍫 in `~/printer_data/config`. You will also be prompted to select and install MCU board_pins templates. This is recommended for faster `mcu.cfg` setup, but you can do it manually later if you prefer.

```bash
wget -O - https://raw.githubusercontent.com/elpopo-eng/klippain-chocolate/main/install.sh | bash
```

Finally, Klippain-🍫 requires a few simple steps to configure and customize it for your printer: please follow the [configuration guide](./docs/configuration.md).

  > **Warning**:
  >
  > General rule to keep the auto-update feature working: **never modify Klippain-🍫 files directly**, but instead add overrides as per [the documentation](./docs/overrides.md)! To proceed, you can modify all the pre-installed templates in your config root folder (`printer.cfg`, `mcu.cfg`, `variables.cfg` and `overrides.cfg`) as they will be preserved on update.

### Installation Options

The install script supports several command line options:

```bash
cd ~/klippain_config
bash ./install.sh [-b <branch_name>] [--reinstall-templates] [--reinstall-addons]
```

Available options:
- `-b` or `--branch`: Select Klippain branch to install
  - `main`: Default stable branch
  - `beta`: Advanced features branch
  - `develop`: Latest development branch
- `--reinstall-templates`: Regenerate MCU templates in `mcus.cfg` (previous file backed up)
- `--reinstall-addons`: Prompt to install optional components like Shaketune


## Removing Klippain-🍫

In case Klippain-🍫 doesn't suit your needs or if you installed it by mistake, you can easily remove Klippain-🍫 and revert to your previous configuration by using the automated uninstall script. During the uninstallation process, the script will remove all specific Klippain-🍫 files and configurations. Additionally, you will be given an option to restore your previously backed-up configuration, allowing your printer to return to its last working state (from before Klippain-🍫 was installed).

To run the uninstall script, execute the following command over SSH:

```bash
wget -O - https://raw.githubusercontent.com/elpopo-eng/klippain-chocolate/main/uninstall.sh | bash
```

  > **Note**:
  >
  > All backups are preserved during the uninstallation process. So, you can easily revert back at any time if you wish to :stuck_out_tongue_winking_eye:


## Support the Project

I strive to accommodate user requests that align with this configuration's design. Feel free to open an issue or a PR for specific hardware device support or new features.

Alternatively, consider buying me a coffee or contributing to new hardware purchases to support my work!
