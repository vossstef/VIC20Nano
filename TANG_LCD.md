# VIC20Nano with LCD Output

Video output is adapted for a 5" TFT-LCD module 800x480 Type [SH500Q01Z](https://dl.sipeed.com/Accessories/LCD/500Q01Z-00%20spec.pdf) (Ilitek ILI6122)

Sipeed sells a 5 inch LCD for the Tang Nano 20k. This LCD has a resultion
of 800x480 pixels and attaches directly to the Tang Nano 20k without using the
HDMI connector. This is supported by all cores. The Tang 20k, 60k and 138k Pro additionally comes with a built-in I2S DAC and audio amplifier which comes
in handy in this setup to add sound output.

> [!NOTE]
> TN20k, TP20k and TN9k: No Dualshock, no D9 retro Joystick, no external RS232 support

# TM60k NEO, LCD, Speaker and M0S

# TM138k Pro, LCD, Speaker and M0S

# TN20k, LCD, Speaker and M0S

**Pinmap TN20k Interfaces LCD Output**<br>
 M0S Dock, LCD, Speaker<br>

![wiring](\.assets/wiring_tn20k_lcd.png)
<br> <br> 

# TP20k, LCD, Speaker, M0S PMOD adapter and M0S

![setup](\.assets/tp20k_lcd.png)


# TN9k, LCD, Speaker and M0S
TN9k lack Audio support therefore external Filter and Amplifier needed.

**low pass filter for Audio Amplifier** <br>
![pinmap](\.assets/audiofilter.png)<br>
Tang Nano 5V connected to Audio Amplifier supply.
Filter Vout connected to input of Amplifier module e.g. Mini PAM8403

 