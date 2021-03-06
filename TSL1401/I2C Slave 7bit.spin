{{
NOTICE:
This object is a draft and has pending revisions.  Check
http://learn.parallax.com/node/103 for updates.  If you have
questions, please email me: alindsay@parallax.com.

See end of file for author, version, copyright and terms of use.
}}

CON

  ACK = 0                                        ' Acknowledge bit = 0
  NACK = 1                                       ' (No) acknowledge bit = 1

VAR

  long addr, sda, scl, maxreps

PUB Init(sdaPin, sclPin, address)

 addr    := address
 sda     := sdaPin
 scl     := sclPin
 maxreps := pollingreps
 
 outa[scl]~                                      ' SCL pullup high
 dira[scl]~
 outa[sda]~                                      ' SDA pullup high
 dira[sda]~

PUB SetPollReps(pollreps)

  maxreps := pollreps

PUB Poll(readwrite) : ackbit | command, i

  ' Poll until acknowledge.  This is especially important if the slave is copying from
  ' buffer to EEPROM.

  i:=0
  ackbit~~                                       ' Make acknowledge 1
  readwrite &= 1
  command := (addr<<1) | readwrite  
  repeat                                         ' Send/check acknowledge loop
    Start                                        ' Send I2C i2c.Start condition
    ackbit := ByteOut(command)                   ' Write command with EEPROM's address
  while (ackbit==NACK) and ++i<maxreps           ' Repeat while acknowledge is not 0
  
PUB Start

  ' I2C start condition.  sda transitions from high to low while the clock is high.
  ' scl does not have the pullup resistor called for in the I2C protocol, so it has to be
  ' set high. (It can't just be set to inByteOut because the resistor won't pull it up.)

  dira[sda]~                                     ' Let pulled up sda pin go high
  dira[scl]~                                     ' scl pin outByteOut-high
  dira[sda]~~                                    ' Transition sda pin low
  dira[scl]~~                                    ' Transition scl pin low

PUB Stop

  ' Send I2C stop condition.  scl must be high as sda transitions from low to high.
  ' See note in Start about scl line.
  dira[sda]~~                                    ' sda -> low
  dira[scl]~                                     ' scl -> high
  dira[sda]~                                     ' sda -> sda transitions to intput
                                                 '        pulled high
PUB ByteOut(b) : ackbit | i

  ' Shift a byte to EEPROM msb first.  Return if EEPROM acknowledged.  Returns
  ' acknowledge bit.  0 = ACK, 1 = NACK.

  b ><= 8                                        ' Reverse bits for shifting msb right
  repeat 8                                       ' 8 reps sends 8 bits
    dira[sda] := !b                              ' Lowest bit sets state of sda
    dira[scl]~                                   ' Pulse the scl line
    dira[scl]~~
    b >>= 1                                      ' Shift b right for next bit
  ackbit := AckIn                                ' Call ByteInAck and return EEPROM's Ack

PUB AckIn : ackbit

  ' ByteIn and return acknowledge bit transmitted by EEPROM after it receives a byte.
  ' 0 = ACK, 1 = NACK.

  dira[sda]~                                     ' sda -> input for slave to control
  dira[scl]~                                     ' Start a pulse on scl
  ackbit := ina[sda]                             ' ByteIn the sda state from slave
  dira[scl]~~                                    ' Finish scl pulse
  
PUB ByteIn(ackbit) : value

  ' Shift in a byte msb first.  

  dira[sda]~                                     ' sda input so slave can control
  repeat 8                                       ' Repeat shift in eight times
    dira[scl] ~                                  ' Start an scl pulse
    value <<= 1                                  ' Shift the value left
    value += ina[sda]                            ' Add the next most significant bit
    dira[scl]~~                                  ' Finish the scl pulse
  AckOut(ackbit)  

PUB AckOut(ackbit)

  ' Transmit an acknowledgement bit (ackbit).

  dira[sda] := !ackbit                           ' Set sda output state to ackbit
  dira[scl]~                                     ' Send a pulse on scl
  dira[scl]~~
  dira[sda]~                                     ' Let go of sda

DAT

  pollingreps long 1  

{{
Author: Andy Lindsay
Version: 0.3
Date:   2012.03.19
Copyright (c) 2011 Parallax Inc.

To-Do:

 - Clock strething

┌──────────────────────────────────────────────────────────────────────────────────────┐
│TERMS OF USE: MIT License                                                             │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}           