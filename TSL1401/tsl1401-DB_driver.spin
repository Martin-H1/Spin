{

┌──────────────────────────────────────────────────────────┐
│                  TSL1401-DB_driver.spin                  │
│(c) Copyright 2010 Philip C. Pilgrim (propeller@phipi.com)│
│(c) Copyright 2012 John Abshier from OBEX Spin object     │ 
│(c) Copyright 2012 Martin C Heermance                     │
│            See end of file for terms of use.             │
└──────────────────────────────────────────────────────────┘

This object provides a TSL1401-DB driver for the Propeller BOE which
is interface compatible with Phil Pi's binary driver. It uses some
Spin code from John Absheir to clock in the pixels with my own code
to call the Prop BOE's ADC.

Version History
───────────────
2010.03.01: Initial release
2012.10.03: Ported to a pure Spin version to allow calling Prop BOE's ADC.
}

CON

OBJ

  adc    : "PropBOE ADC"                               ' A/D Converter on PropBOE

VAR

  long clk_mult
  long exp_time
  byte cogpixels[128]           ' buffer for image.
  long adcPin                   ' camera analog output, si, clock and LED control pins
  long siPin
  long clkPin
  long ledPin
  long ms                       ' clock cycles for 1 ms
  long expTimeCorr              ' expTime correction for Spin timing overhead
  byte minpix
  byte maxpix
  byte minloc
  byte maxloc

PUB start (ao, si, clk, led)

'' Start the driver.
  adcPin := ao
  siPin := si
  clkPin := clk
  ledPin := led

  dira[siPin]~~
  dira[clkPin]~~
  dira[ledPin]~~
  outa[siPin]~
  outa[clkPin]~
  outa[ledPin]~~
  
  clk_mult := clkfreq * 10 / 2441
  setexp_us(10000)                           ' default to a 1/500 sec exposure
  expTimeCorr := 240_000_000 / clkfreq      ' adjust expTimeCorr for different clock frequencies

PUB stop


PUB snap | i, pixel

'' Snap a picture.
  longfill(@cogpixels,0,32)                 ' zero image array

  outa[siPin]~~                             ' start exposure interval
  outa[clkPin]~~
  outa[siPin]~
  outa[clkPin]~
  repeat 256                                ' clock out pixels for one shot
    !outa[clkPin]
  outa[clkPin]~

  waitcnt(exp_time + cnt)                   ' wait exposure time
  outa[siPin]~~                             ' end exposure
  outa[clkPin]~~
  outa[siPin]~
  outa[clkPin]~
  pixel := adc.In(adcPin) >> 2              ' 10 bits returned, but we only want 8
  cogpixels[0] := pixel

    ' Initialize the statistics
  minpix := pixel
  maxpix := pixel
  minloc := 0
  maxloc := 0

  repeat i from 1 to 127
    outa[clkPin]~~                          ' high
    pixel := adc.In(adcPin) >> 2            ' 10 bits returned, but we only want 8
    cogpixels[i] := pixel
    outa[clkPin]~

    if pixel > maxpix
      maxloc := i
      maxpix := pixel

    if pixel < minpix
      minloc := i
      minpix := pixel

PUB getpix(addr)

'' Transfer the pixels to a long-aligned 128-byte array at addr.
  bytemove(addr, @cogpixels, 128)

PUB getstats

'' Return stats from the last snap, packed in a single long as:
''
''  31    24 23    16 15     8 7      0
'' ┌────────┬────────┬────────┬────────┐
'' │ MaxLoc │ MinLoc │ MaxPix │ MinPix │ , where
'' └────────┴────────┴────────┴────────┘
''
'' MinPix is the value (1 - 255) of the darkest pixel,
'' MaxPix is the value (1 - 255) of the brightest pixel,
'' MinLoc is the index (0 - 127) of the darkest pixel, and
'' MaxLoc is the index (0 - 127) of the brightest pixel.
  return   (maxloc << 24) | (minloc << 16) | (maxpix << 8) | minpix

Pub ledOn
{{ Turns LED connected to mezzanine connector on.  As you look at the camera use the bottom center and
   right sockets }} 
  outa[ledPin]~~

Pub ledOff
{{ Turns LED connected to mezzanine connector off }} 
  outa[ledPin]~

PUB setexp_us(exptime_us)

'' Set the exposure time to exptime_us microseconds (20 us min for 80 MHz clock).

  setexp((exptime_us * clk_mult) >> 12)

PUB setexp(exptime)

'' Set the exposure time to exptime system clock ticks (from 1600 to ?).
  exp_time := exptime  - expTimeCorr      ' Reduce for program overhead

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}