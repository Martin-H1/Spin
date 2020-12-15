CON

         _clkmode       = xtal1 + pll16x
        _xinfreq        = 5_000_000

VAR

  long pixels[32], stats 
  word pixaddr

OBJ

  lin   : "tsl1401-db_driver"
  sio   : "FullduplexSerial"

PUB start | i, exp, maxpix

  exp := clkfreq / 120
  lin.start(0, 1, 2, 3)
  sio.start(31, 30, 0, 38400)
  repeat
    lin.setexp(exp)
    lin.snap
    lin.getpix(@pixels)
    maxpix := lin.getstats >> 8 & $ff
    if (maxpix > $e0)
      exp := exp * 95 / 100
    elseif (maxpix < $c0)
      exp := exp * 105 / 100
    stats := lin.getstats
    sio.tx(0)
    sio.str(string("1401", 13))   'String for receiver to sync on.
    repeat i from 0 to 127
      sio.tx(byte[@pixels][i])
      
      