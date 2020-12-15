{{
   File...... tsl1401_follower.spin
   Purpose... Line follower program for the BOE-Bot, using the TSL1401-DB.'
   Author.... PBasic original by Phil Pilgrim, Bueno systems, Inc.
   Author.... Ported to Spin by Martin Heermance
   E-mail....
   Started... 18 August 2007
   Updated... 05 October 2012

 This program uses the TSL1401-DB linescan imager daughterboard in
 conjunction with a Propeller board on a BOE-Bot along dark line made
 with black tape on a light-colored floor.
}}

CON

  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000

  ' These constants need to be set for each robot.
  DARK          = FALSE         ' Value assignd to "which" for dark pixels.
  LIGHT         = TRUE          ' Value assigned to "which" for light pixels.

  WHICH         = DARK          ' Set for dark line on light floor. Change to LIGHT, otherwise.  
  LINE          = 17            ' Line width for 1/2-inch tape. Adjust proportionally for other sizes.      

  ao            = 0             ' TSL1401R's analog output (threhsolded by Propeller).    
  si            = 1             ' TSL1401R's SI pin.
  clk           = 2             ' TSL1401R's CLK pin.
  led           = 3             ' LED strobe input.

  RMOTOR        = 15
  LMOTOR        = 14

  ' These constants need to be tuned for each servo. My servos are really out of
  ' whack and the left constants are much different that you would expect.    
  RSTOP         = 2000
  LSTOP         = 2000
  RSLOW         = 700
  RTURN         = 700
  LSLOW         = 800
  LTURN         = 900
  
DAT                               
  CLREOL        byte "\033[K", 0 ' ASCII terminal control codes to match PBASIC commands.       
  CRSRXY        byte "\033[%d;%dH", 0
  HOME          byte "\033[H", 0
  
OBJ

  BS2   : "BS2_Functions"       ' Create BS2 Object 

VAR
  long pdata[4]                 ' buffer for image.   
  long clk_mult
  long exp
  long avg
  long count
  long cog, stack[32]
  long lpulse, rpulse 

Pub Main   | i
  BS2.start (31,30)             ' Initialize BS2 Object timing, Rx and Tx pins for DEBUG     

  ' Output the startup tone.
  BS2.FREQOUT(4, 1000, 440)  

  ' Initialize the Servo pins.
  lpulse := 750
  rpulse := 750
  cog := cognew(ServoPal, @stack)    

  ' Pause for 100 ms.                                    
  exp := 75                     ' Set initial exposure (strobe) time.

  repeat                          ' Begin the scan-and-process loop.
    GetPix                        ' Obtain a pixel scan.
    AvgPix                        ' Find the dark pixel count and average position.

    BS2.DEBUG_DEC(count)
    BS2.DEBUG_STR(STRING(" "))
    BS2.DEBUG_DEC(avg)
    BS2.DEBUG_CR

    if count < (line - 2)           ' If count is too low,
      exp := exp - 1 + (which << 1) ' Adjust exposure according to line color.
    elseif (count > line + 2)       ' If too high,
      exp := exp + 1 - (which << 1) '  adjust the other way.

    exp := exp #> 10 <# 80          ' Make sure exposure time is reasonable.
    if (count => (line >> 1) AND count =< (line << 1)) ' If count isn't WAY off, use position.
      if (avg => 64)                ' If line is to the right, 
        rpulse := RSLOW             '  steer right proportional to the error.
        lpulse := LTURN - (avg >> 1)
      else                          ' Else, if line is to the left,
        rpulse := RTURN - (127 - (avg >> 1)) '  steer left proportional to the error.
        lpulse := LSLOW
    else                            ' If pixel count is WAY off,
      rpulse := RSTOP               '   just stop until we get the
      lpulse := LSTOP               '   exposure time right.

Pub GetPix
{{
 Acquire 128 thresholded pixels from sensor chip.
 exp is the exposure time in microseconds.
}}
  BS2.SHIFTOUT(si, clk, 1, BS2#LSBFIRST, 1) ' Clock out the SI pulse.
  BS2.PWM(clk, 128, 1)              ' Rapidly send 150 or so CLKs.                       
  BS2.PWM(led, 255, exp)            ' PWM LED low for exposure time.
  BS2.SHIFTOUT(si, clk, 1, BS2#LSBFIRST, 1) ' Clock out another SI pulse.
                                    ' Read 8 words (128 bits) of data.
  
  pdata[0] := BS2.SHIFTIN(ao, clk, BS2#LSBPRE, 32)
  pdata[1] := BS2.SHIFTIN(ao, clk, BS2#LSBPRE, 32)
  pdata[2] := BS2.SHIFTIN(ao, clk, BS2#LSBPRE, 32)
  pdata[3] := BS2.SHIFTIN(ao, clk, BS2#LSBPRE, 32)

Pub Pixel(idx)
{{
 Extract the pixel at bit offset idx from the four long array of bits.
}}
  return (pdata[idx / 32] & (1 << (idx // 32))) <> 0  
 
Pub AvgPix | i
{{
 Find average location of pixels of the type indicated by which (0 = dark;
 1 = light). For the sake of speed, consider only the even pixels. The
 position will still cover the full range, but the count will be half of
 what it would be if if every pixel were considered.
}}
  count := 0
  avg := 0
  repeat i from 0 TO 127 STEP 2
    if Pixel(i) == which
      avg := avg + i
      count := count + 1

  if count <> 0
    avg := avg / count

Pri ServoPal
{{
  Simulates a servo pal by using a cog to pulse servos in the background
}}
  repeat
    BS2.PULSOUT(RMOTOR, rpulse)
    BS2.PULSOUT(LMOTOR, lpulse)
    BS2.Pause(15)