CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

  SI = 4           'Encoder Output on Pin 4       - Encoder 4
  CLK = 2          'Encoder CLK on Pin 2          - Encoder 2
  CS = 6           'Encoder activation on Pin 6   - Encoder 6
  TotalLEDs = 93

  R1Start  = 0
  R1End    = 31
  R2Start  = 32
  R2End    = 55
  R3Start  = 56
  R3End    = 71
  R4Start  = 72
  R4End    = 83
  R5Start  = 84
  R5End    = 91

  R1Len    = 32    
  R2Len    = 24   
  R3Len    = 16   
  R4Len    = 12   
  R5Len    = 8   

        
OBJ       
  pst : "PST_Driver"                       
  rgb : "WS2812B_RGB_LED_Driver_v2"           'Include WS2812B_RGB_LED_Driver object and call it "rgb" for short

DAT
Colors long  rgb#red
       long  rgb#green
       long  rgb#blue
       long  rgb#white
       long  rgb#cyan
       long  rgb#magenta
       long  rgb#yellow
       long  rgb#chartreuse 
       long  rgb#orange
       long  rgb#aquamarine
       long  rgb#pink 
       long  rgb#turquoise
       long  rgb#realwhite
       long  rgb#indigo
       long  rgb#violet
 
RStart word 0,32,56,72,84     'array of Start adddresses for each ring   
{ 
R1Start  = 0
R2Start  = 32  
R3Start  = 56 
R4Start  = 72 
R5Start  = 84
 }
REnd word 31,55,71,83,91      'array of End adddresses for each ring

{
R1End    = 31
R2End    = 55
R3End    = 71      
R4End    = 83 
R5End    = 91
}
RLen word 32,24,16,12,8       'array of LED length for each ring   
{          
R1Len    = 32 
R2Len    = 24 
R3Len    = 16 
R4Len    = 12 
R5Len    = 8    }                            
VAR       
  long target, CW, position, PrevPosition,position2, PrevPosition2, position3, PrevPosition3, position4, PrevPosition4, position5, PrevPosition5 'position = current motor position, target = setpoint servo position, CW = HBridge diretion 
  long Stack1[100], Stack2[100]      
                           
PUB Main | Lit 
          
rgb.start(0,TotalLEDs)

pst.start                         'Start the "PST_Driver" object on Cog 1
 {

position:= Encoder    'Shift 6 bits to right to only use upper 10 position bits
PrevPosition:= 0
repeat 
  position:= Encoder
  if ||(position - PrevPosition) > 2
    pst.str(string("Position is:" ))
    pst.dec(position)
    pst.NewLine
    PrevPosition:=position

}

position:= Encoder    'Shift 6 bits to right to only use upper 10 position bits
PrevPosition:= 0
'PrevPosition2:= 0
rgb.AllOff
repeat
  ManualControl
  'SecondHand
Pub ManualControl 
  position:= Encoder
  rgb.LED((position/(1024/R1Len)), rgb#blue)
    if ||(position/(1024/R1Len) - PrevPosition) > 0
      rgb.LED(PrevPosition, rgb#off)
      'rgb.AllOff
      'pst.str(string("Position is:" ))
      'pst.dec((position/(1024/R1Len))) 
      'pst.NewLine
      'pst.dec(PrevPosition)            
      PrevPosition:=position/(1024/(R1Len))
  {position2:=position/(1024/R2Len)+R2Start
  rgb.LED((position2), rgb#red)
    if ||(position2 - PrevPosition2) > 0
      rgb.LED(PrevPosition2, rgb#off)
        'rgb.AllOff
        'pst.str(string("Position is:" ))
        'pst.dec(position/33)
       ' pst.NewLine
       ' pst.dec(PrevPosition)            
      PrevPosition2:=position2
      
  position3:=position/64+55
  rgb.LED((position3), rgb#green)
    if ||(position3 - PrevPosition3) > 0
      rgb.LED(PrevPosition3, rgb#off)
        'rgb.AllOff
        'pst.str(string("Position is:" ))
        'pst.dec(position/33)
       ' pst.NewLine
       ' pst.dec(PrevPosition)            
      PrevPosition3:=position3

  position4:=position/85+71
  rgb.LED((position4), rgb#orange)
    if ||(position4 - PrevPosition4) > 0
      rgb.LED(PrevPosition4, rgb#off)
        'rgb.AllOff
        'pst.str(string("Position is:" ))
        'pst.dec(position/33)
       ' pst.NewLine
       ' pst.dec(PrevPosition)            
      PrevPosition4:=position4

  position5:=position/128+83
  rgb.LED((position5), rgb#cyan)
    if ||(position5 - PrevPosition5) > 0
      rgb.LED(PrevPosition5, rgb#off)
        'rgb.AllOff
        'pst.str(string("Position is:" ))
        'pst.dec(position/33)
       ' pst.NewLine
       ' pst.dec(PrevPosition)            
      PrevPosition5:=position5 }
Pub SecondHand | i, j, TotalTime, T1, T2, T3, T4, T5, TAll 

  TotalTime:= 60               'Total Time to go around
  T1:=TotalTime/R1Len          'Equal divisions of time for each LED based on ring length
  T2:=TotalTime/R2Len
  T3:=TotalTime/R3Len
  T4:=TotalTime/R4Len
  T5:=TotalTime/R5Len  
  TAll:= TotalTime/TotalLEDs

{ ctra[30..26]:=%1000
  ctra[5..0]:=Lit
  phsa~ 
  frqa:= T1
         }
    'rgb.SetSection(R1Start, i, rgb#orange)
    {repeat i from 0 to R5End 
      rgb.LED(Lit, rgb#blue) 
      waitcnt( }
   { repeat i from 0 to R5End 
      rgb.SetSection(R1Start, i, rgb#blue) 
      waitcnt(clkfreq*TAll+cnt)}

   repeat j from 0 to 5
    repeat i from 0 to REnd[j] 
      rgb.SetSection(RStart[j], i, rgb#green) 
      waitcnt(clkfreq*T1/10+cnt)
    rgb.AllOff        
    {
    repeat i from 0 to R5End 
      rgb.SetSection(R1Start, i, rgb#green) 
      waitcnt(clkfreq/30+cnt)    
 
    repeat i from 0 to R5End 
      rgb.SetSection(R1Start, i, rgb#cyan) 
      waitcnt(clkfreq/30+cnt)
      
    repeat i from 0 to R5End 
      rgb.SetSection(R1Start, i, rgb#violet) 
      waitcnt(clkfreq/30+cnt)
                    }
PUB Encoder : PosData
dira[CLK]~~
dira[CS]~~  
dira[SI]~               'Pin 4 set to input to receive encoder data, Pins 2 and 6 set as outputs
PosData:=0 
{outa[CLK..CS]:=%100001
outa[CLK..CS]~ }
outa[CLK]~~
outa[CS]~~
outa[CS]~
outa[CLK]~
'waitcnt(cnt+clkfreq/100)                  'Activate encoder
repeat 16
   outa[CLK]~~
   PosData:=(PosData <<1)+ina[SI]    'Get position data from 16-bit Encoder value, starting with MSB                   
   outa[CLK]~  
PosData:= PosData >> 6
outa[CS]~~                  'Deactivate encoder 