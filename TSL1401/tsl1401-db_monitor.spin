CON

         _clkmode       = xtal1 + pll16x
        _xinfreq        = 5_000_000

VAR

  long pixels[32], stats 
  word pixaddr

OBJ

  lin   : "tsl1401-db_driver"
  sio   : "FullduplexSerial"
  
PUB start | i

  lin.start(0, 1, 2, 3)
  sio.start(31, 30, 0, 38400) 

  lin.setexp(clkfreq / 40)
  repeat
    lin.ledOn
    lin.snap
    lin.ledOff
    lin.getpix(@pixels)
    stats := lin.getstats
    sio.tx(0)
    sio.str(string("1401", 13))   'String for receiver to sync on.
    repeat i from 0 to 127
      sio.tx(byte[@pixels][i])
      
      