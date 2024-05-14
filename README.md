# VIC20Nano
The VIC20Nano is a port of some [MiST](https://github.com/mist-devel/mist-board/wiki) and 
[MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/) components of the
[ VIC20 FPGA core ](https://en.wikipedia.org/wiki/VIC-20) to the 
[Tang Nano 20k FPGA board](https://wiki.sipeed.com/nano20k) with a new VHDL top level and HDMI Video and Audio Output.<br>
It has also been ported to the [Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html)  ([Gowin GW5A-25](https://www.gowinsemi.com/en/product/detail/60/)) too (no Dualshock 2, no Paddles and no Retro DB9 Joystick support).<br>

Original VIC-20 core by [MikeJ (Mike Johnson)](https://www.fpgaarcade.com/author/mikej/) and [WoS (Wolfgang Scherr)](https://www.researchgate.net/profile/Wolfgang_Scherr2)<br>
All HID, SDcard and [BL616 MCU](https://en.bouffalolab.com/product/?type=detail&id=25) µC firmware by [Till Harbaum](http://www.harbaum.org/till/mist)<br>
c1541 by [darfpga](https://github.com/darfpga)<br>

Features:
* PAL 832x576p@50Hz or NTSC 800x480p@60Hz HDMI Video and Audio Output
* USB Keyboard via [Sipeed M0S Dock BL616 µC](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)
* USB Joystick via µC
* [legacy D9 Joystick](https://en.wikipedia.org/wiki/Atari_CX40_joystick) (Atari / Commodore digital type) [MiSTeryNano shield](https://github.com/harbaum/MiSTeryNano/tree/main/board/misteryshield20k/README.md)<br>
* Joystick emulation on Keyboard [Numpad](https://en.wikipedia.org/wiki/Numeric_keypad)<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Keys & Stick as Joystick<br>
* [Dualshock 2 Controller Gamepad](https://en.wikipedia.org/wiki/DualShock) Sticks as [Paddle](https://www.c64-wiki.com/wiki/Paddle) Emulation (analog mode)<br>
* emulated [1541 Diskdrive](https://en.wikipedia.org/wiki/Commodore_1541) on FAT/extFAT microSD card<br>
* C1541 DOS ROM selection
* Cartridge ROM (*.PRG) loader
* Direct BASIC program file (*.PRG) injection loader
* Tape (*.TAP) image loader [C1530 Datasette](https://en.wikipedia.org/wiki/Commodore_Datasette)
* Loadable 8K Kernal ROM (*.BIN)
* On Screen Display (OSD) for configuration and D64 image selection<br>
* 3K, 8K, 16K, 24K, 32K RAM Expansion<br>
* 8K RAM at $A000 as loadable Cartridge Slot<br>
<br>
<img src="./.assets/vic20nano.png" alt="image" width="80%" height="auto">
<br>

HID interfaces aligned in pinmap and control to match [MiSTeryNano project's bl616 misterynano_fw](https://github.com/harbaum/MiSTeryNano/tree/main/firmware/misterynano_fw).<br> Basically BL616 µC on the Sipeed M0S Dock acts as USB host for USB devices and as an OSD controller using a [SPI communication protocol](https://github.com/harbaum/MiSTeryNano/blob/main/SPI.md).<br>

**Note** PROJECT IS STILL WORK IN PROGRESS
<br>
## Installation

The installation of VIC20 Nano on the Tang Nano 20k board can be done using a Linux PC or a Windows PC
[Instruction](INSTALLATION_WINDOWS.md).<br>

## VIC20Nano on Tang Primer 25K
See [Tang Primer 25K](TANG_PRIMER_25K.md)

## emulated Diskdrive c1541
Emulated 1541 on a regular FAT/exFAT formatted microSD card.<br>
Copy a D64 Disk image to your sdcard and rename it to **disk8.d64** as default boot image.<br>
Add further D64 images as you like and insert card in TN slot. Power Cycle TN. LED 0 acts as Drive activity indicator.<br> 
Disk directory listing:<br> 
LOAD"$",8<br>
LIST<br> 
Load first program from Disk:<br> 
LOAD"*",8<br>
RUN<br>
JiffyDOS can be used as well known Speedloader. Change in OSD the c1541 DOS to Jiffy too.<br>

## RAM Expansion
Size and Region can be activated in several steps. A change takes effect immediately.<br>
Take care to activate the correct size of needed expansion before you load *.PRG and *.TAP !
|Expansion| $0400 3k | $2000 8k |$4000 8k |$6000 8k |
| - | - | - |- |- |
| Block | 0 | 1 |2 |3 |
| 3k | x | - |- |- |
| 8k | -  | x  |- |- |
| 16k | -  | x |x |- |
| 24k | -  | x  |x |x |
| 32k | x  | x  |x |x |

## Cartridge ROM Loader (.PRG/.CRT)
Cartrige ROM can be loaded via OSD file selection.<br>
Be aware that the core doesn't support the [VICE EMU](https://vice-emu.sourceforge.io/vice_16.html) file format.<br>
Typical VIC20 Cartridge ROMS with ending .PRG have a two byte header indicating the loading location.<br>
8k Cartridges to be loadeded directly as such. 16k or larger Cartridges have to be loaded in several steps and the file with ending xyz-a000.prg have to be loaded last. First load xyz-2000.prg, xyz-4000.prg or xyz-6000.prg and then xyz-a000.prg at last. The Cartridge will start after that last step automatically.<br>
Copy a 8K xyz-a000.prg ROM to your sdcard and rename it to **vic20crt.crt** as default boot cartridge.<br>
Detach Cartrige by OSD CRT selection **No Disk** , **Save settings** and System **Cold Boot**.<br>

## BASIC Program Loader (.PRG)
A BASIC Program *.PRG file can be loaded via OSD file selection.<br>
Copy a *.PRG to your sdcard and rename it to **vic20prg.prg** as default boot basic program.<br>
Prevent PRG load by OSD PRG selection **No Disk** , **Save settings** and **Reset**.<br>

## Tape Image Loader (*.TAP)
A [Tape](https://en.wikipedia.org/wiki/Commodore_Datasette) *.TAP file can be loaded via OSD file selection.<br>
In order to start a tape download select normal VIC20 Kernal (mandatory) and type: LOAD<br>
The file is loaded automatically as soon as file selected via OSD (no need to press PLAY TAPE button).<br>
After some seconds the filename of the to be loaded file will be shown and it will take time...<br>
Copy a *.TAP to your sdcard and rename it to **vic20tap.tap** as default boot tape.<br>
Prevent TAP load at boot or for **Tape unload** OSD TAP selection **No Disk** , **Save settings** and **Reset**.<br>

## Kernal Loader (.BIN)
The CBM factory PAL type is the power-up default Kernal.<br>
Kernal ROM files *.BIN can be loaded via OSD selection (e.g. JiffyDOS VIC20).<br>
Copy a 8K VIC20 Kernal ROM *.BIN to your sdcard and rename it to **vic20kernal.bin** as default boot Kernal.<br>
Prevent Kernal load by OSD Kernal BIN selection **No Disk** and **Save settings** and do a **power-cyle** of the board.<br>

## loadable Cartridge RAM Slot
Some Cartridge based games can be be simply loaded from a [VIC20](https://vic20reloaded.com) D64 Disk Image.<br>
Example: 16 k Cartridge Game<br>
Enable RAM Expansion at $2000 (or $6000) and Cartridge region $A000<br>
Leave OSD setting CRT writeable setting as enabled as first approach.
Save setting and do a Cold Boot Reset.<br>
``` LOAD "xyz.200",8,1```   (Block 1)<br>
``` or LOAD "xyz.600",8,1```   (Block 3)<br>
``` LOAD "xyz.A00",8,1```   (Block 5)<br>
Start Game by command: SYS40960 (general start Address for Cartridge Slot)<br> or better perform a Reset via OSD.<br>
There are also some cartridge games on D64 Image with a loader that themselves further reload the needed RAM regions and autostart (you have to activate RAM regions beforhand).<br> A loaded Cartridge can be exited by disabling memory region $A000 + Cold Reset via OSD. In order to trial another game just activate again (after reset !) the $A000 memory and load another game.

## Push Button utilization
* S2 keep pressed during power-up for programming Flash<br>
* S1 reserved <br>

## OSD
invoke by F12 keypress<br>
* Reset<br>
* Cold Reset<br>
* Audio Volume + / -<br>
* Scanlines effect %<br>
* Widescreen activation<br>
* Screen centering<br>
* PAL / NTSC Video mode<br>
* HID device selection for Joystick Port<br>
* RAM Expansion $A000(8k), $6000(8k), $4000(8k), $2000(8k), $0400(3k)<br>
* Cartridge Write protection<br>
* c1541 Drive disk image selection<br>
* c1541 Disk write protetcion<br>
* c1541 Reset<br>
* c1541 DOS ROM selection<br>
* Loader (CRT/PRG/BIN/TAP) file selection<br>

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

| LED | function | TN20K | TP25K | TM138K |
| --- |        - | -     | -     | -      |
| 0 | c1541 activity  | x | x | x |
| 1 | D64 selected | x | - | x |
| 2 | CRT seleced | x | - | x |
| 3 | PRG selected | x | - | x |
| 4 | Kernal selected  | x | - | x |
| 5 | TAP selected | x | - | x |

Solid 'red' of the c1541 led after power-up indicates a missing DOS in Flash<br>

**Multicolor RGB LED**
* **<font color="green">green</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;all fine and ready to go<br>
* **<font color="red">red</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;something wrong with SDcard / default boot image<br>
* **<font color="blue">blue</font>**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;µC firmware detected valid FPGA core<br>
* **white**&ensp;&thinsp;&ensp;&thinsp;&ensp;&thinsp;-<br>
## Powering
Prototype circuit with Keyboard can be powered by Tang USB-C connector from PC or a Power Supply Adapter. 
## Synthesis
Source code can be synthesized, fitted and programmed with GOWIN IDE Windows or Linux.<br>
Alternatively use the command line build script gw_sh.exe build_tn20k.tcl or build_tp25k.tcl<br>
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

[Sipeed M0S Dock](https://wiki.sipeed.com/hardware/en/maixzero/m0s/m0s.html)<br>
[Sipeed Tang Nano 20k](https://wiki.sipeed.com/nano20k) <br>
or [Sipeed Tang Primer 25k](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html)<br>
and [PMOD DVI](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DVI)<br>
and [PMOD TF-CARD](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_TF-CARD)<br>
and [PMOD SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM)<br>
and [M0S PMOD adapter](https://github.com/harbaum/MiSTeryNano/tree/main/board/m0s_pmod/README.md)
 or ad hoc wiring + soldering.<br>
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
