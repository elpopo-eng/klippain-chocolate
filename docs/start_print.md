# start_print sequence

The `START_PRINT` sequence is modular and fully customizable. A default `START_PRINT` sequence is auto-populated based on your probe choice (TAP, Dockable, Inductive).
But if for some reasons you still want to modify it, you can defined a new `startprint_actions_array` variable in variable.cfg. You can use any number of action or even duplicate some actions if needed, also you can append what ever macro you want by using this format : 

`{'module|command': 'StandardModuleOrCommand', 'parameters': "MyMacroParameter", 'inject_base_parameter': True|False}`

Available standart module: 
    1. `"HEATSOAK_BED"`
    1. `"EXTRUDER_PREHEATING"`
    1. `"HEATSOAK_CHAMBER"`
    1. `"EXTRUDER_HEATING"`
    1. `"TILTING"`
    1. `"PURGE"`
    1. `"CLEAN"`
    1. `"Z_CALIB"`
    1. `"BED_MESH"`
    1. `"PRIMELINE"`

`inject_base_parameter` is used for injected all `START_PRINT` parameter if you need them

You may have something like this :
```
variable_startprint_actions_array:[
      {'module' : 'HEATSOAK_BED'},
      {'module' : 'EXTRUDER_PREHEATING'},
      {'module' : 'HEATSOAK_CHAMBER'},
      {'module' : 'TILTING'},
      {'command': 'G28', 'parameters': 'Z', 'inject_startprint_params' : False},
      {'module' : 'EXTRUDER_HEATING'},
      {'command': 'MAKE_POOP_IN_BUCKET'},
      {'module' : 'Z_CALIB'},
      {'module' : 'BED_MESH'},
      {'command': 'CHECK_MESH'},
      {'command': 'PLAY_CUCARACHA', 'inject_startprint_params' : True},
      {'command': 'PRIME_Z_LINE'}
     ] 
```

## Available parameters for `START_PRINT`

The `START_PRINT` macro also checks if the parameters sent from the slicer are valid. Availables parameters are
`BED_TEMP`, `EXTRUDER_TEMP`, `CHAMBER_TEMP`, `Z_ADJUST`, `SOAK`, `CHAMBER_MAXTIME`, `MATERIAL`, `SIZE`, `MESH`,`ADAPTIVE_PRIMELIME`, `INITIAL_TOOL`, `REFERENCED_TOOLS`, `SYNC_MMU_EXTRUDER`, `TOTAL_LAYER`.

If a user need a custom parameters, its name can be added in variables. (_eg. `variable_start_gcode_user_params: ["MY_CUSTOM_PARAM1", "MY_CUSTOM_PARAM2" ]`_ )
