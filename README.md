# VIC20Nano
The VIC20Nano is a port of some
[MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/) components of the
[ VIC20 FPGA core ](https://en.wikipedia.org/wiki/VIC-20) to the 
[Tang Nano 20k FPGA board](https://wiki.sipeed.com/nano20k) with a new VHDL top level and HDMI Video and Audio Output.<br><br>
Original VIC-20 core by MikeJ (Mike Johnson) and T65 WoS (Wolfgang Scherr)<br>
All HID and [BL616 MCU](https://en.bouffalolab.com/product/?type=detail&id=25) µC firmware by Till Harbaum<br>
c1541 by https://github.com/darfpga<br>

Features:
* PAL 832x576p@50Hz or NTSC 800x480p@60Hz HDMI Video and Audio Output
* USB Keyboard via [Sipeed M0S Dock BL616 µC](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)
* USB Joystick via µC
* [legacy D9 Joystick](https://en.wikipedia.org/wiki/Atari_CX40_joystick) (Atari / Commodore digital type) [MiSTeryNano shield](https://github.com/harbaum/MiSTeryNano/tree/main/board/misteryshield20k/README.md)<br>
* Joystick emulation on Keyboard Numpad<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Keys & Stick as Joystick<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Sticks as [Paddle](https://www.c64-wiki.com/wiki/Paddle) Emulation (analog mode)<br>
* emulated [1541 Diskdrive](https://en.wikipedia.org/wiki/Commodore_1541) on FAT/extFAT microSD card<br>
* c1541 DOS ROM selection (CBM DOS)
* On Screen Display (OSD) for configuration and D64 image selection<br>
* 3K, 8K, 16K, 24K RAM Expansion<br>
* 8K RAM at $A000 as loadable Cartridge Slot<br>
<br>
<img src="./.assets/vic20nano.png" alt="image" width="80%" height="auto">
<br>

HID interfaces aligned in pinmap and control to match [MiSTeryNano project's bl616 misterynano_fw](https://github.com/harbaum/MiSTeryNano/tree/main/firmware/misterynano_fw).<br> Basically BL616 µC acts as USB host for USB devices and as an OSD controller using a [SPI communication protocol](https://github.com/harbaum/MiSTeryNano/blob/main/SPI.md).<br>

**Note** PROJECT IS STILL WORK IN PROGRESS
<br>
## Installation

The installation of VIC20 Nano on the Tang Nano 20k board can be done using a Linux PC or a Windows PC
[Instruction](INSTALLATION_WINDOWS.md).<br>

## emulated Diskdrive c1541
Emulated 1541 on a regular FAT/exFAT formatted microSD card.<br>
Copy a D64 Disk image to your sdcard and rename it to **disk8.d64** as default boot image.<br>
Add further D64 images as you like and insert card in TN slot. Power Cycle TN. LED 0 acts as Drive activity indicator.<br> 
c1541 **CBM DOS** ROM to be selected from OSD and saved !<br>
Disk directory listing:<br> 
LOAD"$",8<br>
LIST<br> 
Load first program from Disk:<br> 
LOAD"*",8<br>
RUN<br>

## loadable Cartridge RAM Slot
Some Cartridge based games can be be simply loaded from a [VIC20](https://vic20reloaded.com) D64 Disk Image.<br>
Example: 16 k Cartridge Game<br>
Enable RAM Expansion at $2000 (or $6000) and $A000<br>
Save setting and do a Cold Boot Reset.<br>
``` LOAD "xyz.200",8,1```   (Block 1)<br>
``` or LOAD "xyz.600",8,1```   (Block 3)<br>
``` LOAD "xyz.A00",8,1```   (Block 5)<br>
Start Game by command: SYS40960 (general start Address for Cartridge Slot)<br>
There are also some cartridge games on D64 Image with a loader that themselves further reload the needed RAM regions and autostart.<br> At the moment a loaded Cartridge can only be exited by a Power Cycle of the TN20k to clean the memory.<br>

## Push Button utilization
* S2 Reset (for Flasher)<br>
* S1 reserved <br>

## OSD
invoke by F12 keypress<br>
* Reset<br>
* Cold Reset + memory scrubbing<br>
* Audio Volume + / -<br>
* Scanlines effect %<br>
* Widescreen activation<br>
* HID device selection for Joystick Port<br>
* RAM Expansion $A000(8k), $6000(8k), $4000(8k), $2000(8k), $0400(3k)<br>
* Cartridge Write protection<br>
* c1541 Drive disk image selection<br>
* c1541 Disk write protetcion<br>
* c1541 Reset<br>
* c1541 DOS ROM selection<br>
* PAL / NTSC Video mode<br>

## Gamecontrol support
legacy single D9 Digital Joystick. OSD: Retro D9<br>
or<br>
USB Joystick(s). OSD: USB #1 or USB #2 <br>
or<br>
Gamepad. OSD: DualShock
<br>**stick digital** for Move and Left **L1** or Right **R1** shoulder Button for Trigger or following **Pad** controls:<br>
| Buttons | - | - |
| - | - | -  |
| Left L1/R1<br>Trigger | triangle button<br>Up  | .  |
| square button<br>Left | - | circle button<br>Right |
| - | cross button<br>Down | - |<br>

or Keyboard **Numpad**. OSD: Numpad<br>
| | | |
|-|-|-|
|0<br>Trigger|8<br>Up|-|
|4<br>Left|-|6<br>Right|
|-|2<br>Down|-|

or Mouse. OSD: Mouse<br>
USB Mouse as c1351 Mouse emulation.

or Paddle. OSD: Paddle<br>
Dualshock 2 Sticks in analog mode as VC-1312 Paddle emulation.<br>
Left **L1 / L2**  and Right **R1 / R2** shoulder Button as Trigger<br>
You have first to set the DS2 Sticks into analog mode by pressing the DS2 ANALOG button. Mode indicated by red light indicator.<br>Configure DIGITAL mode (press ANALOG button again) when using the Joystick mode agin. OSD: DS2<br>

## Keyboard 
 ![Layout](\.assets/keymap.gif)
 Tape Play not implemented.

## LED UI
0 c1541 Drive activity. Solid 'red' after power-up indicates a missing DOS in Flash<br>
1 unused<br>
2 unused<br>
3 M0S Dock detect<br>
4 System LED 0<br>
5 System LED 1<br>

**Multicolor RGB LED**
* **<font color="green">green</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;all fine and ready to go<br>
* **<font color="red">red</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;something wrong with SDcard / default boot image<br>
* **<font color="blue">blue</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;µC firmware detected valid FPGA core<br>
* **white**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;-<br>
## Powering
Prototype circuit with Keyboard can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized, fitted and programmed with GOWIN IDE Windows or Linux.<br>
## Pin mapping 
see pin configuration in .cst configuration file
## HW circuit considerations
**Pinmap TN20k Interfaces** <br>
 Sipeed M0S Dock, digital Joystick D9 and DualShock Gamepad connection.<br>
 ![wiring](\.assets/wiring_spi_irq.png)

**Pinmap D-SUB 9 Joystick Interface** <br>
- Joystick interface is 3.3V tolerant. Joystick 5V supply pin has to be left floating !<br>
![pinmap](\.assets/vic20-Joystick.png)

| Joystick pin | Tang Nano pin | FPGA pin | Joystick Function |
| ----------- | ---   | --------  | ----- |
| 1 | J6 9  | 28   | Joy3 RIGHT | 28 |
| 2 | J6 11  | 25 | Joy2 LEFT | 25 |
| 3 | J6 10 | 26 | Joy1 DOWN | 26 |
| 4 | J5 12 | 29 | Joy0 UP | 29 |
| 5 | - | - | POT Y | - |
| 6 | J5 8 | 27 | FIRE B.| 27 |
| 7 | n.c | n.c | 5V | - |
| 8 | J5 20 | - | GND | - |
| 9 | - | - | POT X | - |

**Pinmap Dualshock 2 Controller Interface** <br>
<img src="./.assets/controller-pinout.jpg" alt="image" width="30%" height="auto">
| DS pin | Tang Nano pin | FPGA pin | DS Function |
| ----------- | ---   | --------  | ----- |
| 1 | J5 18 | 71 MISO | JOYDAT  |
| 2 | J5 19 | 53 MOSI  | JOYCMD |
| 3 | n.c. | - | 7V5 |
| 4 | J5 15 | - | GND |
| 5 | J5 16| - | 3V3 |
| 6 | J5 17 | 72 CS | JOYATN|
| 7 | J5 20 | 52 MCLK | JOYCLK |
| 8 | n.c. | - | JOYIRQ |
| 9 | n.c. | - | JOYACK |


## Getting started

In order to use this Design the following things are needed:

[Sipeed Tang Nano 20k](https://wiki.sipeed.com/nano20k) <br>
[Sipeed M0S Dock](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)<br>
microSD or microSDHC card FAT/exFAT formatted<br>
TFT Monitor with HDMI Input and Speaker<br>
<br>

| HID and Gamecontrol Hardware option | needs | alternative option |Primer 25K|Mega 138K|
| ----------- | --- | ---  | ---| -|
| USB Keyboard | [USB-C to USB-A adapter](https://www.aliexpress.us/item/3256805563910755.html) | [4 port mini USB hub](https://a.aliexpress.com/_EIidgjH)  |x|x|
| [USB Joystick(s)](https://www.speedlink.com/en/COMPETITION-PRO-EXTRA-USB-Joystick-black-red/SL-650212-BKRD)| [4 port mini USB hub](https://a.aliexpress.com/_EIidgjH) | - |x|x|
| USB Mouse | [4 port mini USB hub](https://a.aliexpress.com/_EIidgjH) | -  |x|x|
| Commodore/[Atari](https://en.wikipedia.org/wiki/Atari_CX40_joystick) compatible retro D9 Joystick| [MiSTeryNano shield](https://github.com/harbaum/MiSTeryNano/tree/main/board/misteryshield20k/README.md)|D-SUB 9 M connector, breadboard to wire everything up, some jumper wires|-|-|
| [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) | Gamepad Adapter Board (Sipeed Joystick to DIP) | breadboard to wire everything up and some jumper wires |-|x|
