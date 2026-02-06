#!/usr/bin/env bash
#################################################
###### AUTOMATED INSTALL AND UPDATE SCRIPT ######
#################################################
# Written by yomgui1 & Frix_x
# @version: 1.5

# CHANGELOG:
#   v1.5: - add options : to choose a custom git branch during install, to reinstall MCU templates 
#   v1.4: added Shake&Tune install call
#   v1.3: - added a warning on first install to be sure the user wants to install klippain and fixed a bug
#           where some artefacts of the old user config where still present after the install (harmless bug but not clean)
#         - automated the install of the Gcode shell commands plugin
#   v1.2: fixed some bugs and adding small new features:
#          - now it's ok to use the install script with the user config folder absent
#          - avoid copying all the existing MCU templates to the user config directory during install to keep it clean
#          - updated the logic to keep the user custom files and folders structure during a backup (it was previously flattened)
#   v1.1: added an MCU template automatic installation system
#   v1.0: first version of the script to allow a peaceful install and update ;)


# Where the user Klipper config is located (ie. the one used by Klipper to work)
USER_CONFIG_PATH="${HOME}/printer_data/config"
# Where to clone Frix-x repository config files (read-only and keep untouched)
FRIX_CONFIG_PATH="${HOME}/klippain_config"
# Path used to store backups when updating (backups are automatically dated when saved inside)
BACKUP_PATH="${HOME}/klippain_config_backups"
# Where the Klipper folder is located (ie. the internal Klipper firmware machinery)
KLIPPER_PATH="${HOME}/klipper"
# Git URL of the Frix-x/klippain repo to use during install (default: official repo)
FRIX_CONFIG_GIT_URL="https://github.com/elpopo-eng/klippain-chocolate.git"

# for update purpose
NEW_INSTALL=false


set -eu
export LC_ALL=C

# Step 1: Verify that the script is not run as root and Klipper is installed.
#         Then if it's a first install, warn and ask the user if he is sure to proceed
function preflight_checks {
    if [ "$EUID" -eq 0 ]; then
        echo "[PRE-CHECK] This script must not be run as root!"
        exit -1
    fi

    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F 'klipper.service')" ]; then
        printf "[PRE-CHECK] Klipper service found! Continuing...\n\n"
    else
        echo "[ERROR] Klipper service not found, please install Klipper first!"
        exit -1
    fi

    if [ ! -f "${USER_CONFIG_PATH}/.VERSION" ]; then
        echo "[PRE-CHECK] New installation of Klippain detected!"
        echo "[PRE-CHECK] This install script will WIPE AND REPLACE your current Klipper config with the full Klippain system (a backup will be kept)"
        echo "[PRE-CHECK] Be sure that the printer is idle before continuing!"
        
        if prompt "[PRE-CHECK] Are you sure want to proceed and install Klippain? (y/N) " n ; then
            echo -e "[PRE-CHECK] Installation confirmed! Continuing...\n"
        else
            echo "[PRE-CHECK] Installation was canceled!"
            exit -1
        fi
    fi
}


# Step 2: Check if the git config folder exist (or download it)
function check_download {
    local frixtemppath frixreponame frixbranchname frixrepourl currentbranch nextbranch
    frixtemppath="$(dirname ${FRIX_CONFIG_PATH})"
    frixreponame="$(basename ${FRIX_CONFIG_PATH})"
    frixbranchname="${FRIX_BRANCH:-main}"
    frixrepourl="${FRIX_CONFIG_GIT_URL}"


    if [ ! -d "${FRIX_CONFIG_PATH}" ]; then
        NEW_INSTALL=true
        echo "[DOWNLOAD] Downloading Klippain repository..."
        if git -C $frixtemppath clone -b $frixbranchname  $frixrepourl $frixreponame; then
            printf "[DOWNLOAD] Download complete!\n\n"
        else
            echo "[ERROR] Download of Klippain git repository failed!"
            exit -1
        fi
    else
        # retrieve current branch
        currentbranch=$(git -C ${FRIX_CONFIG_PATH} rev-parse --abbrev-ref HEAD)
        # check if the user asked for a branch change
        nextbranch="${FRIX_BRANCH:-$currentbranch}"

        echo -e "[DOWNLOAD] Klippain repository already found locally.\n" \
            "  Repo : $frixrepourl branch : $currentbranch\nContinuing...\n"
        
        # if the branch requested is different than the current one, ask the user if he wants to switch
        if [[ "${nextbranch}" != "${currentbranch}" ]]; then
            if prompt "[UPDATE] Current branch is '$currentbranch', do you want to switch to branch '$nextbranch'? (Y/n) " y; then
                echo "[UPDATE] Switching branch..."
                git -C ${FRIX_CONFIG_PATH} switch $nextbranch
                echo "[UPDATE] Change branch '$currentbranch' -> '$nextbranch' done!"
                currentbranch=$nextbranch
            else
                echo -e "[UPDATE] Branch switch canceled by user. Continuing with current branch '$currentbranch'...\n"
                nextbranch=$currentbranch
            fi
        fi

        # update: required if script run in ssh instead of moonraker
        if [[ "${currentbranch}" == "${nextbranch}" ]]; then
            echo "[UPDATE] Checking for updates to Klippain repository..."

            git -C ${FRIX_CONFIG_PATH} fetch origin $nextbranch
            LOCAL=$(git -C ${FRIX_CONFIG_PATH} rev-parse @)
            REMOTE=$(git -C ${FRIX_CONFIG_PATH} rev-parse @{u})

            if [ $LOCAL = $REMOTE ]; then
                echo -e "[UPDATE] Klippain repository is already up to date!\n"
            else
                echo "[UPDATE] Updates found! Downloading latest changes..."
                if git -C ${FRIX_CONFIG_PATH} pull --ff-only origin $nextbranch; then
                    echo -e "[UPDATE] Klippain repository updated successfully!\n"
                else
                    echo "[ERROR] Failed to update Klippain repository! Please resolve any conflicts manually."
                    exit -1
                fi
            fi
        else
            echo -e "[UPDATE] Skipping update check. Continuing...\n"
        fi
    fi
}


# Step 3: Backup the old Klipper configuration
function backup_config {
    if [ ! -e "${USER_CONFIG_PATH}" ]; then
        printf "[BACKUP] No previous config found, skipping backup...\n\n"
        return 0
    fi

    mkdir -p ${BACKUP_DIR}

    # Copy every files from the user config ("2>/dev/null || :" allow it to fail silentely in case the config dir doesn't exist)
    cp -fa ${USER_CONFIG_PATH}/. ${BACKUP_DIR} 2>/dev/null || :
    # Then delete the symlinks inside the backup folder as they are not needed here...
    find ${BACKUP_DIR} -type l -exec rm -f {} \;

    # If Klippain is not already installed (we check for .VERSION in the backup to detect it),
    # we need to remove, wipe and clean the current user config folder...
    if [ ! -f "${BACKUP_DIR}/.VERSION" ]; then
        rm -fR ${USER_CONFIG_PATH}
    fi

    printf "[BACKUP] Backup of current user config files done in: ${BACKUP_DIR}\n\n"
}


# Step 4: Put the new configuration files in place to be ready to start
function install_config {
    echo "[INSTALL] Installation of the last Klippain config files"
    mkdir -p ${USER_CONFIG_PATH}

    # Symlink Frix-x config folders (read-only git repository) to the user's config directory
    for dir in config macros scripts moonraker addons; do
        ln -fsn ${FRIX_CONFIG_PATH}/$dir ${USER_CONFIG_PATH}/$dir
    done

    # Detect if it's a first install by looking at the .VERSION file to ask for the config
    # template install. If the config is already installed, nothing need to be done here
    # as moonraker is already pulling the changes and custom user config files are already here
    if [ ! -f "${BACKUP_DIR}/.VERSION" ]; then
        printf "[INSTALL] New installation detected: config templates will be set in place!\n\n"
        find ${FRIX_CONFIG_PATH}/user_templates/ -type d -name 'mcu_defaults' -prune -o -type f -print | xargs cp -ft ${USER_CONFIG_PATH}/
        install_mcu_templates
    # Reinstall templates if the user asked for it
    elif $REINSTALL_TEMPLATES; then
        echo "[INSTALL] Reinstalling config templates as requested by user!"
        echo -e "[INSTALL] ${RED}WARNING: this will OVERWRITE your current mcu.cfg file!${DEFAULT}"
        prompt "[INSTALL] Are you sure you want to reinstall the config templates? (y/N)" n &&
        cat /dev/null > ${USER_CONFIG_PATH}/mcu.cfg &&
        install_mcu_templates
    else
        printf "[INSTALL] Existing installation detected: skipping config templates installation!\n\n"
    fi

    # CHMOD the scripts to be sure they are all executables (Git should keep the modes on files but it's to be sure)
    chmod +x ${FRIX_CONFIG_PATH}/*.sh
    chmod +x ${FRIX_CONFIG_PATH}/scripts/*.py
    
    # Symlink the gcode_shell_command.py file in the correct Klipper folder (erased to always get the last version) not Kalico
    if [ ! -f "${KLIPPER_PATH}/klippy/extras/gcode_shell_command.py" ] || [ -L "${KLIPPER_PATH}/klippy/extras/gcode_shell_command.py" ]; then
        ln -fsn ${FRIX_CONFIG_PATH}/scripts/gcode_shell_command.py ${KLIPPER_PATH}/klippy/extras
    else
        echo "[INSTALL] gcode_shell_command.py plugin already installed, skipping..."
    fi
    

    # Create or update the config version tracking file in the user config directory
    git -C ${FRIX_CONFIG_PATH} rev-parse HEAD > ${USER_CONFIG_PATH}/.VERSION
}

# Helper function to ask and install the MCU templates if needed
function install_mcu_templates {
    local  file_list main_template  toolhead_template

    # Check and exit if the user do not wants to install an MCU template file
    if ! prompt "[CONFIG] Would you like to select and install MCU wiring templates files? (Y/n) " y; then
        printf "[CONFIG] Skipping installation of MCU templates. You will need to manually populate your own mcu.cfg file!\n\n"
        return
    fi

    # If "yes" was selected, let's continue the install by listing the main MCU template
    file_list=()
    while IFS= read -r -d '' file; do
        file_list+=("$file")
    done < <(find "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/main" -maxdepth 1 -type f -print0)
    file_list=($(printf '%s\n' "${file_list[@]}" | sort))
    echo "[CONFIG] Please select your main MCU in the following list:"
    for i in "${!file_list[@]}"; do
        echo "  $((i+1))) $(basename "${file_list[i]}")"
    done

    read < /dev/tty -p "[CONFIG] Template to install (or 0 to skip): " main_template
    if [[ "$main_template" -gt 0 ]]; then
        # If the user selected a file, copy its content into the mcu.cfg file
        filename=$(basename "${file_list[$((main_template-1))]}")
        cat "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/main/$filename" >> ${USER_CONFIG_PATH}/mcu.cfg
        printf "[CONFIG] Template '$filename' inserted into your mcu.cfg user file\n\n"
    else
        printf "[CONFIG] No template selected. Skip and continuing...\n\n"
    fi

    # Next see if the user use a toolhead board
    # Check if the user wants to install a toolhead MCU template
    if prompt "[CONFIG] Do you have a toolhead MCU and want to install a template? (y/N) " n; then
        file_list=()
        while IFS= read -r -d '' file; do
            file_list+=("$file")
        done < <(find "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/toolhead" -maxdepth 1 -type f -print0)
        file_list=($(printf '%s\n' "${file_list[@]}" | sort))
        echo "[CONFIG] Please select your toolhead MCU in the following list:"
        for i in "${!file_list[@]}"; do
            echo "  $((i+1))) $(basename "${file_list[i]}")"
        done

        read < /dev/tty -p "[CONFIG] Template to install (or 0 to skip): " toolhead_template
        if [[ "$toolhead_template" -gt 0 ]]; then
            # If the user selected a file, copy its content into the mcu.cfg file
            filename=$(basename "${file_list[$((toolhead_template-1))]}")
            cat "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/toolhead/$filename" >> ${USER_CONFIG_PATH}/mcu.cfg
            printf "[CONFIG] Template '$filename' inserted into your mcu.cfg user file\n\n"
        else
            printf "[CONFIG] No toolhead template selected. Skip and continuing...\n\n"
        fi
    fi

    # Next see if the user use an MMU/ERCF board
    # Check if the user wants to install an MMU/ERCF MCU template
    if prompt "[CONFIG] Do you have an MMU/ERCF MCU and want to install a template? (y/N) " n; then
        file_list=()
        while IFS= read -r -d '' file; do
            file_list+=("$file")
        done < <(find "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/mmu" -maxdepth 1 -type f -print0)
        file_list=($(printf '%s\n' "${file_list[@]}" | sort))
        echo "[CONFIG] Please select your MMU/ERCF MCU in the following list:"
        for i in "${!file_list[@]}"; do
            echo "  $((i+1))) $(basename "${file_list[i]}")"
        done

        read < /dev/tty -p "[CONFIG] Template to install (or 0 to skip): " mmu_template
        if [[ "$mmu_template" -gt 0 ]]; then
            # If the user selected a file, copy its content into the mcu.cfg file
            filename=$(basename "${file_list[$((mmu_template-1))]}")
            cat "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/mmu/$filename" >> ${USER_CONFIG_PATH}/mcu.cfg
            echo "[CONFIG] Template '$filename' inserted into your mcu.cfg user file"
            printf "[CONFIG] Note: keep in mind that you have to install the HappyHare backend manually to use an MMU/ERCF with Klippain. See the Klippain documentation for more information!\n\n"
        else
            printf "[CONFIG] No MMU/ERCF template selected. Skip and continuing...\n\n"
        fi
    fi

    # Next see if the user use a Scanner type Cartographer3D
    # Check if the user wants to install a Scanner MCU template
    if prompt "[CONFIG] Do you have an Scanner (like Cartographer3D) MCU and want to install a template? (y/N) " n; then
        file_list=()
        while IFS= read -r -d '' file; do
            file_list+=("$file")
        done < <(find "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/scanner" -maxdepth 1 -type f -print0)
        file_list=($(printf '%s\n' "${file_list[@]}" | sort))
        echo "[CONFIG] Please select your Scanner MCU in the following list:"
        for i in "${!file_list[@]}"; do
            echo "  $((i+1))) $(basename "${file_list[i]}")"
        done

        read < /dev/tty -p "[CONFIG] Template to install (or 0 to skip): " scanner_template
        if [[ "$scanner_template" -gt 0 ]]; then
            # If the user selected a file, copy its content into the mcu.cfg file
            filename=$(basename "${file_list[$((scanner_template-1))]}")
            cat "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/scanner/$filename" >> ${USER_CONFIG_PATH}/mcu.cfg
            echo "[CONFIG] Template '$filename' inserted into your mcu.cfg user file"
            printf "[CONFIG] Note: keep in mind that you have to install the Cartographer3D backend manually to use a cartographer scanner. See the Klippain documentation for more information!\n\n"
        else
            printf "[CONFIG] No scanner template selected. Skip and continuing...\n\n"
        fi
    fi

   # Finally see if the user use an expander board
    # Check if the user wants to install an expander MCU template
    if prompt "[CONFIG] Do you have an expander board and want to install a template? (y/N) " n; then
        file_list=()
        while IFS= read -r -d '' file; do
            file_list+=("$file")
        done < <(find "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/expander" -maxdepth 1 -type f -print0)
        file_list=($(printf '%s\n' "${file_list[@]}" | sort))
        echo "[CONFIG] Please select your expander MCU in the following list:"
        for i in "${!file_list[@]}"; do
            echo "  $((i+1))) $(basename "${file_list[i]}")"
        done

        read < /dev/tty -p "[CONFIG] Template to install (or 0 to skip): " expander_template
        if [[ "$expander_template" -gt 0 ]]; then
            # If the user selected a file, copy its content into the mcu.cfg file
            filename=$(basename "${file_list[$((expander_template-1))]}")
            cat "${FRIX_CONFIG_PATH}/user_templates/mcu_defaults/expander/$filename" >> ${USER_CONFIG_PATH}/mcu.cfg
            printf "[CONFIG] Template '$filename' inserted into your mcu.cfg user file\n\n"
        else
            printf "[CONFIG] No expander template selected. Skip and continuing...\n\n"
        fi
    fi
}

# Installation of addons if any
function install_addons {
    if $NEW_INSTALL || $REINSTALL_ADDONS; then
        echo "[ADDONS-INSTALL] New installation detected, installing addons..."
        if prompt "[ADDONS-INSTALL] Do you want to install/update klippain-shaketune addon now? (Y/n) " y; then
            wget -O - https://raw.githubusercontent.com/Frix-x/klippain-shaketune/main/install.sh | bash
            # Shake&Tune installation code goes here
        else
            echo "[ADDONS-INSTALL] Skipping klippain-shaketune addon installation as per user request."
        fi

        # Future addons installation can be added here

    else
        if [ -d "${HOME}/klippain_shaketune" ]; then
            echo "[ADDONS-INSTALL] klippain-shaketune addon detected, updating..."
            wget -O - https://raw.githubusercontent.com/Frix-x/klippain-shaketune/main/install.sh | bash
        fi


    fi
}

# Step 5: restarting Klipper
function restart_klipper {
    echo "[POST-INSTALL] Restarting Klipper..."
    sudo systemctl restart klipper
}

## utility functions and main script body below ##

# Colors helpers
RED=$'\033[1;31m'
MAGENTA=$'\033[0;35m'
DEFAULT=$'\033[0m'

prompt() {
  local default="Yn"
  [ $# -eq 2 ] && [ ${2^} = "N" ] && default="yN"
 
  while true; do
    read -p "${MAGENTA}$1${DEFAULT}" yn
    case $yn in
    [Yy]*) return 0 ;;
    "")
      [ $default = "yN" ] && return 1 # Return 1 if N, 0 if Y is default
      return 0 # Return 0 on Enter key press (Y as default)
      ;; 
    [Nn]*) return 1 ;;
    esac
    line_count=$(echo $1 | wc -l)
    for ((i=0; i<$line_count; i++)); do
      echo -ne '\e[1A\e[K' # Move cursor up and clear line
    done
  done
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -b|--branch) FRIX_BRANCH="$2"; shift ;;
      --reinstall-templates) REINSTALL_TEMPLATES=true ;;
      --reinstall-addons) REINSTALL_ADDONS=true ;;
      --) shift; break ;;
      -?*) echo "Unknown option: $1" ;;
    esac
    shift
  done
}
REINSTALL_TEMPLATES=false
REINSTALL_ADDONS=false
NEW_INSTALL=false
BACKUP_DIR="${BACKUP_PATH}/$(date +'%Y_%m_%d-%H%M%S')"

printf "\n======================================\n"
echo "- Klippain install and update script -"
printf "======================================\n\n"

# Run steps
parse_args "$@"
preflight_checks
check_download
backup_config
install_config
install_addons
restart_klipper

echo "[POST-INSTALL] Everything is ok, Klippain installed and up to date!"
echo "[POST-INSTALL] Be sure to check the breaking changes on the release page: https://github.com/elpopo-eng/klippain-chocolate/releases"
