{{Input Output Pins.spin

This object measures voltage at the A0, A1,
A2 or A3 sockets.  Its In method returns
a value from 0 to 1023, representing the
number of 1024ths of 5 V applied the socket.

  Example Program with adc Nickname
 ┌───────────────────────────────────────────────┐
 │ ''Displays measurement from A3 input          │
 │ ''as number of 1024ths of 5 V.                │
 │                                               │
 │ OBJ                                           │
 │                                               │
 │   system : "Propeller Board of Education"     │
 │   adc    : "PropBOE ADC"                      │
 │   pst    : "Parallax Serial Terminal Plus"    │
 │                                               │
 │ PUB Go | adcVal                               │
 │                                               │
 │   system.Clock(80_000_000)  ' Clock -> 80 MHz │
 │                                               │
 │   adcVal := adc.In(3)       'Measure A3       │
 │   pst.Dec(adcVal)           'Display value    │
 │                             '(1024ths of 5 V) │
 └───────────────────────────────────────────────┘

NOTE       This object samples at a maximum
           of 1.16 ksps.  The ADC is can
           sample at rates up to 20 kHz with
           the PropBOE ADC (ASM).spin object.
           This object has a few updates
           pending before it can be added to
           this package.   
           
BUGS       Please send bug reports,
&          questions, suggestions, 
UPDATES    and improved versions of this
           object to alindsay@parallax.com,
           and check back periodically for
           updated versions.                    
}}

VAR

  long configured, started
  long adc[4]
  long cog, stack[32], lockID

OBJ

  i2c    : "I2C Slave 7bit"

PUB Start(chlist) : success
{{Optional method, not required for A/D measurements

If your code calls this before the first call to the In
method, it will launch the A/D conversion process into
another cog.  The advantage here is a 2x sampling rate
increase, but it's still only 1.16 ksps for 1 channel,
0.558 ksps for 2 channels, etc.

For sampling rates up to 22 ksps, use the
PropBOE ADC (ASM) object instead.  See NOTE section at
the start of the file for more info.

Parameters:

  chlist  - Binary value that represents which channels
            to sample.  For example if you set chlist to
            %0101, it will repeatedly sample channels
            2 and 0.  %1010 will repeatedly sample
            channels 3 and 1.  %1111 will sample all the
            channels, %0001 will sample only channel 0,
            and so on...
Returns:
            
  success - Returns a value in the 1 to 8 range if it
            successfully launched a cog, or 0 if no cogs
            or locks are available.          
}}            

  if (lockID := locknew) == -1
    return success := false
  
  success := cog := (cognew(AdcLoop(chlist), @stack) + 1)

PUB Stop
{{Stops the A/D conversion process and frees a cog and
a lock bit.  You can still call the In method after calling
this method.  The only difference is that the cog that
calls the In method will be the cog that also does the A/D
conversion at a slightly slower rate.}}

  if cog
    cogstop(cog~ - 1)
    
  lockret(lockID)  

PUB In(channel) : adcval | pointer, acks, chan
{{Measure input voltage at one of the Propeller Board
of Education's analog inputs: A0, A1, A2 are sockets
below the breadboard, and A3 is connected to an
amplified microphone output.

Parameter: channel use 0, 1, 2, or 3 for A0, A1, A2,
                   or A3}}
  ifnot configured
    i2c.Init(29, 28, %010_0001)
     
  ifnot cog  
    pointer := |< (channel + 4)
    acks := i2c.poll(0)
    if acks == i2c#NACK
      i2c.Init(29, 28, %010_0011)
      acks := i2c.poll(0)
    acks += i2c.ByteOut(pointer)
    acks += i2c.poll(1)
    adcval := i2c.ByteIn(0)
    chan := adcval>>4
    adcval &= %1111
    adcval <<= 8  
    adcval += i2c.ByteIn(1)
    adcval >>= 2
    if acks <> 0 or chan <> channel
      adcval := -1
  else
    repeat until not lockset(lockID)
    adcVal := adc[channel]
    lockclr(lockID)
     
PRI AdcLoop(chlist) | pointer, acks, chan, idx, list, i 
{{Measure input voltage at one of the Propeller Board
of Education's analog inputs: A0, A1, A2 are sockets
below the breadboard, and A3 is connected to an
amplified microphone output.

Parameter: channel use 0, 1, 2, or 3 for A0, A1, A2,
                   or A3.   
}}
  ifnot configured
    i2c.Init(29, 28, %010_0001)
    
  pointer := (chList << 4)
  acks := i2c.poll(0)
  if acks == i2c#NACK
    i2c.Init(29, 28, %010_0011)
    acks := i2c.poll(0)
  acks += i2c.ByteOut(pointer)
  acks += i2c.poll(1)
  
  repeat
    list := chList
    repeat i from 0 to 3
      if list & 1 == 1
        repeat until not lockset(lockID)
        adc[i] := i2c.ByteIn(0)
        chan := adc[i] >> 4
        adc[i] &= %1111
        adc[i] <<= 8  
        adc[i] += i2c.ByteIn(0)
        adc[i] >>= 2
        if acks <> 0 or chan <> i
          adc := -1
        lockclr(lockID)
      list >>= 1
         
PUB Config(sda, scl, addr)
{{You do not need to call this method if you are using
a Propeller Board of Education.

Optional configuration method for using the AD7993 with
other boards (not Propeller BOE).  If you are using the
Propeller BOE, there's no need to call this method.  If
you are configuring the ADC to a different set of I/O
pins, call this method before calling Start or In
methods.

Parameters: sda  - Propeller I/O pin connected to I2C
                   serial data pin
            scl  - Propeller I/O pin connected to I2C
                   serial clock pin
            addr - I2C address the AD7993 is set to
                   See AD7993 datasheet info on setting
                   the chip's I2C address.
}}

  configured := sda << 24 + scl << 16 + addr <<1 

DAT
{{
File:      PropBOE ADC.spin
Date:      2012.06.13
Version:   0.33
Author:    Andy Lindsay
Copyright: (c) 2012 Parallax Inc.

Updates:

  v0.33
    - Automatically detects Propeller BOE ADC and
      configures i2c object accordingly.
      Rev A has AD7993BRUZ-1, Rev B has AD7993BRUZ-0 

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify, merge,     │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}



          