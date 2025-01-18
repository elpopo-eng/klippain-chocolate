# Cartographer Probe Configuration

To configure your setup for the Cartographer probe, you need to activate the `include` directive by adding the following line to your configuration files. Make sure to remove other probe types from your configuration:

```plaintext
include config/hardware/probes/cartographer_survey.cfg
```

This can be added either in `override.cfg` or in another file included in `override.cfg`. Below is an example configuration:

```plaintext
# the values in the example above correspond to a 350mm bed.

[mcu scanner]
#canbus_uuid: 0ca8d67388c2
#serial:/dev/serial/by-id/usb-Cartographer_614e_-if00

[scanner]
#   Offsets are measured from the center of your coil to the tip of your nozzle
#   on a level axis. It is vital that this is accurate.
x_offset: 0                          
# Adjust for your Cartographer's offset from the nozzle to the middle of the coil

y_offset: 15 # offset for standard printed carriage
#y_offset: 23.6 # offset for CNC Cartographer     
# Adjust for your Cartographer's offset from the nozzle to the middle of the coil

backlash_comp: 0.005

scanner_touch_location: 175,175 # Set to the center of the bed
scanner_touch_z_offset: 0 # This will be added to the offset at the end of every successful touch

[bed_mesh] 
mesh_min: 40,25
mesh_max: 310,310
zero_reference_position: 175,175
speed: 300
horizontal_move_z: 2
probe_count: 25,25
fade_start: 0.6
fade_end: 10.0
algorithm: bicubic
```

### Adjustments

Modify the following parameters according to your bed size and toolhead:

- `[scanner] y_offset`
- `[scanner] scanner_touch_location`

- `[bed_mesh]  mesh_min`
- `[bed_mesh]  mesh_max`
- `[bed_mesh]  zero_reference_position`



### Adding Variables

In your `variable.cfg`, add the following lines:

```plaintext
variable_tap_max_probing_temp: 150
variable_tap_deactivation_zhop: 5
```

