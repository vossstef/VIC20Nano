# VIC20Nano on Tang Primer 20K

VIC20Nano can be used in the [Tang Primer 20K with Dock ext Board](https://wiki.sipeed.com/hardware/en/tang/tang-primer-20k/primer-20k.html).

The M0S required to control the VIC20Nano is to be mounted in the PMOD 0 slot (MIC ARRAY) with the help of the [M0S PMOD adapter](https://github.com/harbaum/MiSTeryNano/tree/main/board/m0s_pmod/README.md). 

Plug the optional Dualshock DS2x2 Interface into PMOD 2 slot (RGB LCD).
[PMOD DS2x2](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2)<br>

Mind direction !

The whole setup will look like this:<br>
![VIC20Nano on TP20K](./.assets/primer20k.png)

If you don't have a **M0S PMOD adapter** at hand then adhoc wiring is feasible needing a soldering iron.<br>
The needed +5V for the M0S Dock can be taken from C1+ Pad by a short soldered wire.<br> 8 single pins are needed to plug into the PMOD apart from the cable that comes along with the M0S Dock package.<br>

|M0S Pin |Signal| M0S Dock   |Primer PMOD| FPGA                  |                                      |
|  - |------|-------------------|-|-------------------|--------------------------------------|
|J3-1| GND  | GND        |3| GND       | GND               |
|J2-1| GND  | GND        |4| GND        | GND               |
|J3-2| +5V  | +5V        |-| n.c        | C1+ Pad !!! +5V Supply for M0S              |
|J2-2| +3V3 | +3V3       |-| n.c            | don't connect !              |
|J3-4| CSN  | GPIO12     |9| R8       | SPI select, active low               |
|J2-4| SCK  | GPIO13     |10| T7      | SPI clock, idle low                  |
|J2-3| MOSI | GPIO11     |12| P6      | SPI data from MCU to FPGA            |
|J3-3| MISO | GPIO10     |11| T6      | SPI data from FPGA to MCU    |
|J3-5| IRQ  | GPIO14     |7| T8       | Interrupt from FPGA to MCU, active low |
|-| -  | -     |5,6,7,8| n.c.       | don't connect |

For 20K Dock kits, it's necessary to enable the FPGA configuration mode before using the Programmer, just put the 1 switch on the dip switch down.  
![DIP Switch SW1 TP20K](./.assets/switch_1_on.png)

On the software side the setup is very simuilar to the original Tang Nano 20K based solution. The core needs to be built specifically
for the different FPGA of the Tang Primer using either the [TCL script with the GoWin command line interface](build_tp20k.tcl) or the
[project file for the graphical GoWin IDE](vic20nano_tp20k.gprj). The resulting bitstream is flashed to the TP20K as usual. So are the c1541 DOS ROMs which are flashed exactly like they are on the Tang Nano 20K. And also the firmware for the M0S Dock is the [same version as for
the Tang Nano 20K](https://github.com/harbaum/MiSTeryNano/tree/main/firmware/misterynano_fw/). Latest binary can be found in the [release](https://github.com/harbaum/MiSTeryNano/releases) section.


<br><br>
**Optional !!!** HW modifications Primer 20K SO-DIMM Module that had been used during design debug. Not needed for normal operation. Rework place with Microscope needed.<br>
- optional: *Access FLASH WP*<br>Wire FLASH pin 3 WP to Q1 Gate / R25 (FPGA pin P12). SPI LCD interface will be sacrificed.<br>
- optional: *Access FLASH HOLD*<br> Wire FLASH pin 7 HOLD to R26-1&2 (FPGA pin F12). SPI LCD interface will be sacrificed.<br>
- optional: *Prevent FPGA booting bitstream from FLASH* <br>
Trace cut of pin 96 signal RECFGn from SO-DIMM connector finger pad. (be very very careful) <br>
Wire FPGA signal MODE1 available at pad of R29 (signal side) to SO-DIMM pin 96 Pad.<br>
By that Dock SW1 position ON (logic high) will prevent booting bitstream from FLASH. For normal boot from Flash SW1 has to be in OFF (logic low) position. FPGA load from SRAM (Programmer) is in any position possible. Solves issue [see also](https://wiki.sipeed.com/hardware/en/tang/tang-primer-20k/primer-20k.html#Successfully-burned-once%2C-but-can%27t-burn-after-that) 