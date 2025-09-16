## TMC sense_resistor

> **Warning**:
>
> For safety reasons, it is required to configure the `sense_resistor`
> parameter in your `mcu.cfg` file for each tmc section. This parameter is
>  crucial for monitoring and protecting your printer's electronics. Ensure
>  that you set the correct value according to your hardware specifications to
>  prevent potential damage or hazards.

## Usual sense_resistor values
Below are the default values used by Klipper. However, your board's values may
 vary. Please consult the manufacturer documentation of your TMC drivers for
 the correct values.

| Driver Chip         | Default Sense Resistor |
|---------------------|------------------------|
| TMC2208 / TMC2209   | 0.110 Ω                |
| TMC2130 / TMC5160   | 0.075 Ω                |

For more information, please refer to the [Klipper documentation](https://www.klipper3d.org/Config_Reference.html#tmc-stepper-driver-configuration).

## Adding the sense_resistor to the Configuration
To add the `sense_resistor` parameter for each stepper, refer to the [override guide](./overrides.md#how-to-write-an-override).

