## Materials Presets Management in Klippain-Chocolate

Klippain's `START_PRINT` macro, adjusts printer behavior based on material presets.

### Default Material Settings

The `gcode_macro _MATERIAL` contains default values for material variables:
```elixir
variable_default: {  
    "pressure_advance": 0.048,
    "pressure_advance_smooth_time": 0.015,
    "retract_length": 0.5,
    "unretract_extra_length": 0,
    "retract_speed": 40,
    "unretract_speed": 30,
    "filter_speed": 80,
    "additional_z_offset": 0,
    "filament_sensor": 1,

    "prime_line_pressure_length": 18,   # distance to push filament to add pressure into hotend (value near purge_retract_distance if you purge before print)
    "prime_line_purge_distance": 30,    # length of filament to purge (in mm)
    "prime_line_flowrate": 10,          # mm3/s used for the prime line
    "purge_retract_distance": 20,       # Amount to retract after purge (in mm) (Should be near the prime_pressure_length)
    "purge_speed": 2.5,                 # Speed to purge (in mm/s)
    "purge_distance": 30,               # Amount to purge (in mm)
    }
```

### Managing Material Presets

Material references are passed from the slicer to the printer via the `start_gcode` (see [start_print.md](./start_print.md)). The material reference is retained across restarts to ensure consistent macros functionality. Use the following macros to manage material presets:

- `SET_MATERIAL`: Add or modify material parameters. If the `NAME` parameter is not provided, it will modify the current material. A prompt will ask if you want to retain the values across restarts. The new material will inherit default settings for any unspecified parameters.
- `REMOVE_MATERIAL`: Delete the material. If the `NAME` parameter is not provided, it will delete the current material. A prompt will ask if you want to permanently remove the material across restarts.
- `SELECT_MATERIAL`: Choose material settings from list. This macro is a UI helper and MUST NOT be used inside `START_PRINT`. 

