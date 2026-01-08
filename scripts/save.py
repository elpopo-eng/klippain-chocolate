#!/usr/bin/env python3

##########################################
###### BASIC SERVICE RESTART SCRIPT ######
##########################################

# Be sure to make this script executable using SSH: type 'chmod +x ./service_restart.py' when in the folder !

# List of services to be checked/restarted
# services = ['KlipperScreen']

#####################################################################
################ !!! DO NOT EDIT BELOW THIS LINE !!! ################
#####################################################################

# # Importer le module sys pour accéder aux arguments de la ligne de commande
# import sys

# # Vérifier si le nombre d'arguments est correct
# if len(sys.argv) != 3:
#     print("Usage: python script.py X Y")
#     sys.exit(1)

# # Récupérer les noms des variables X et Y depuis les arguments de la ligne de commande
# variable_X = sys.argv[1]
# variable_Y = sys.argv[2]

# # Vérifier si la variable X existe dans Klipper
# if variable_X in locals() or variable_X in globals():
#     # Remplacer la valeur de la variable X par celle de la variable Y
#     exec(f"{variable_X} = {variable_Y}")
#     print(f"La valeur de {variable_X} a été remplacée par celle de {variable_Y}")
# else:
#     print(f"La variable {variable_X} n'existe pas dans Klipper.")




# # Vérifier le type de sonde et ajuster la configuration en conséquence
# probe_type_enabled = printer['gcode_macro _USER_VARIABLES'].probe_type_enabled

# if probe_type_enabled in ['dockable', 'inductive_virtual', 'vorontap']:
#     # Remplacer la valeur de z_offset par position_endstop
#     printer.configfile.settings.probe.z_offset = printer.configfile.save_config_pending_items.stepper_z.position_endstop
# elif probe_type_enabled in ['inductive', 'none']:
#     # Remplacer la valeur de position_endstop par celle de stepper_z.position_endstop
#     printer.configfile.save_config_pending_items.stepper_z.position_endstop = printer.configfile.settings.probe.z_offset


# Importer le module configparser pour manipuler les fichiers de configuration
import os
import configparser

# Récupérer le chemin complet du fichier overrides.cfg
overrides_cfg_path = "/home/pi/printer_data/config/test.cfg"

# Vérifier le type de sonde et ajuster la configuration en conséquence
probe_type_enabled = printer['gcode_macro _USER_VARIABLES'].probe_type_enabled

# Charger le fichier overrides.cfg
overrides_cfg = configparser.ConfigParser()
overrides_cfg.read(overrides_cfg_path)

# Vérifier si les variables existent et afficher les résultats
if hasattr(printer.configfile.save_config_pending_items, 'probe') and hasattr(printer.configfile.save_config_pending_items.probe, 'z_offset'):
    print("Variable 'printer.configfile.save_config_pending_items.probe.z_offset' existe:", printer.configfile.save_config_pending_items.probe.z_offset)
else:
    print("La variable 'printer.configfile.save_config_pending_items.probe.z_offset' n'existe pas.")

if hasattr(printer.configfile.save_config_pending_items, 'stepper_z') and hasattr(printer.configfile.save_config_pending_items.stepper_z, 'position_endstop'):
    print("Variable 'printer.configfile.save_config_pending_items.stepper_z.position_endstop' existe:", printer.configfile.save_config_pending_items.stepper_z.position_endstop)
else:
    print("La variable 'printer.configfile.save_config_pending_items.stepper_z.position_endstop' n'existe pas.")

# Si les variables existent, effectuer les modifications dans overrides.cfg
if probe_type_enabled in ['dockable', 'inductive_virtual', 'vorontap']:
    # Remplacer la valeur de z_offset par celle de save_config_pending_items.probe.z_offset si elle existe
    if 'probe' in printer.configfile.save_config_pending_items and 'z_offset' in printer.configfile.save_config_pending_items.probe:
        overrides_cfg.set('probe', 'z_offset', str(printer.configfile.save_config_pending_items.probe.z_offset))
elif probe_type_enabled in ['inductive', 'none']:
    # Remplacer la valeur de position_endstop par celle de save_config_pending_items.stepper_z.position_endstop si elle existe
    if 'stepper_z' in printer.configfile.save_config_pending_items and 'position_endstop' in printer.configfile.save_config_pending_items.stepper_z:
        overrides_cfg.set('stepper_z', 'position_endstop', str(printer.configfile.save_config_pending_items.stepper_z.position_endstop))

# Écrire les modifications dans le fichier overrides.cfg
with open('test.cfg', 'w') as configfile:
    overrides_cfg.write(configfile)