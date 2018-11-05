CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

 'ENCODER CONSTANTS
  
  HSI = 4           'Encoder Output on Pin 4       - Encoder 4
  HCLK = 2          'Encoder CLK on Pin 2          - Encoder 2
  HCS = 6           'Encoder activation on Pin 6   - Encoder 6
  {
  ArmSI = ?           'Encoder Output on Pin      - Encoder 4
  ArmCLK = ?          'Encoder CLK on Pin          - Encoder 2
  ArmCS = ?           'Encoder activation on Pin    - Encoder 6
 }
 
  'MOTOR CONSTANTS
  EPWMPin = 8                        'PWM signal sent out to H-bridge chip to control motor's speed  
  EDir = 9                        'Directional control pin 1=CW 0=CCW (when facing the motor)

  HPWMPin = 10                       'Hourglass rotation PWM control
  HDir = 11                       'Hourglass rotation direction
  BackLimit = 14                  'Limit Switch pin. Restricts retraction
  FrontLimit = 15                 'Limit Switch pin. Restricts extension
  
 'LED CONSTANTS
  TotalLEDs=93
  
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
   
  MaxInt = 40                                '15 colors in length, violet is last one     
   
'E REFERS TO EXTENSION MOTOR
'H REFERS TO HOURGLASS ROTATION MOTOR AND HOURGLASS ENCODERS
'ARM REFERS TO HOUR HAND ROTATION MOTOR AND ENCODER

  
OBJ       
  pst : "PST_Driver"                       
  rgb : "WS2812B_RGB_LED_Driver_v2"           'Include WS2812B_RGB_LED_Driver object and call it "rgb" for short

DAT
Colors long  rgb#red              'Array called "Colors" containing the 15 preprogrammed colors
       long  rgb#green            'e.g. red can be referenced by calling Colors[0]
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
  long EDutyCycle, HDutyCycle, target 'DutyCycle=high time of PWM signal
  long Stack1[10], Stack2[100], Stack3[100]     
  long position, PrevPosition, HGposition, HGPrevPosition 'position = current motor position, target = setpoint servo position, CW = HBridge diretion
  long ExtTime, retract, contact, StartTime, Flipping, idle
PUB Main | Lit
                                     {
                                     Checkpoint 4 gameplan? Arm extends to gear, flips hour glass, then execute then count out 5 minutes through the lights?
                                     Possibly mount a second hour glass and rotate between them?
                                     }
                                     



  coginit(1,PWM(EPWMPin, HPWMPin),@Stack1)    'Start PWM method on Cog 1 passing A_speed Hub RAM address
  
  pst.start                         'Start the "PST_Driver" object on Cog 2
  
  StartTime:= False
  Flipping:= False
  coginit(3, Lights, @Stack3)
  rgb.start(0,TotalLEDs)           'Start the RGB driver on with output on Pin 0                                
  dira[EPWMpin..HDir]~~               'Set directions of PWMpin and Dir pins to outputs
  dira[FrontLimit]~                   'Set Limit switch pins as inputs
  dira[BackLimit]~
  
HGposition:= Encoder(HCLK, HCS, HSI)          'Get Hourglass position from encoder
HGPrevPosition:= 0
{Armposition:= Encoder(ArmCLK, ArmGCS, ArmSI)  'Get Arm position from  '
ArmPrevPosition:= 0          }


rgb.AllOff

repeat
  ExtensionDemo
  ManualControl
   SecondHand
Pub Lights

  Rotary_Sweep
  Target_Sweep
  Int_Sweep
  Pie
  waitcnt(clkfreq/4+cnt)
  repeat 5
    SecondHand
    'ManualControl

Pub ExtensionDemo | extend
  ExtTime:= 4                   'Extend for 4 s
  
  repeat
    idle:= True                        'Play demo lights until extension starts
    rgb.AllOff  
    pst.str(string("Enter 1 to extend: "))
    extend:=pst.GetDec #>0 <#1         'Output the 0 or 1 to the H-Bridge chip's direction pin
    idle:= False
    if extend == 1
      outa[EDir]~~                      'Set Extension motor direction outward
      EDutyCycle:=100                   'Set Extension motor's duty cycle ** Probably want this to slow down based on encoder position as it nears the gear 
                                        
      repeat until contact == True      'Extend until arm at contact position 
        'waitcnt(clkfreq*(ExtTime)+cnt) 
        if ina[FrontLimit] == 1         'Check for high signal by making contact with iimt switch
          contact:=True
          
      contact:=False                    'Reset limit Switch
      EDutyCycle~~                      'Turn off extension motor
      pst.NewLine
      pst.str(string("Contact!"))
      
    Flipping:=True                   'Start running ManualControl Light method
    waitcnt(cnt+clkfreq)             'Pause for motor to stop
    
    outa[HDir]~~                       'Set hourglass rotation                 
    HDutyCycle:=100                   'Set Hourglass motor duty cycle

    if HGPosition < 512                'Ideally, this is absolute.  Checks whether position is greater than the absolute position associated w/ vertical hourglass
      target := HGPosition + 512       'Sets target position to be 512 AKA 1/2 roation away from its current position
      pst.NewLine
      pst.str(string("target: "))
      pst.dec(target)

    if HGPosition > 512
      target := HGPosition - 512
      pst.NewLine
      pst.str(string("target: "))
      pst.dec(target)

    repeat until HGPosition => target           'Move until encoder reads that position has exceeded target position (if rotating clockwise)
      HGposition:= Encoder(HCLK, HCS, HSI)      'Get Hourglass position from encoder
      if ||(HGPosition - target) > 0       
        pst.NewLine
        pst.str(string("HGPosition: "))
        pst.dec(HGPosition)  
   {                   
    repeat until ||(HGPosition - target) <2  'Encoder postion of hourglass is target --> 180 degrees different  
      HGposition:= Encoder(HCLK, HCS, HSI)          'Get Hourglass position from encoder
      if ||(HGPosition - target) > 0
        pst.NewLine
        pst.str(string("HGPosition: "))
        pst.dec(HGPosition)   }
    HDutyCycle~                        'Again, may want to slow down as near target
                
    Flipping := False                   'Stop Running ManualControl Light method   
    pst.NewLine                  
    pst.str(string("Flipped!"))
    StartTime := True                  'Start Running SecondHand light method
   
              
    Outa[EDir]~                        'Set Extension motor direction inward      
    EDutyCycle:=100                     'Set Extension motor's duty cycle ** Probably want this to slow down based on encoder position
                                       'as it nears the gear
    repeat until retract == True       'Extend until arm at retract position ** Set by encoder position and limit switch
      'waitcnt(clkfreq*(ExtTime)+cnt)  
      if ina[BackLimit] == 1           'Check for contact with limit switch
        retract:=True
    retract:=False
         
    EDutyCycle~                        'Turn off extension motor  
    pst.NewLine                  
    pst.str(string("Done!"))
    pst.NewLine
    retract:= False
    Extend:=False                                   
    waitcnt(clkfreq+cnt)
  

    
PUB CenterMotion          long ArmDir, ArmDutyCycle, ArmPosition, ArmTarget, ArmZero  'These should become global vars 
                                                                                      'ArmZero may have to be an array of the vertical hourglass zero psitions    
 repeat

    pst.str(string("Enter 1 to rotate: "))
    extend:=pst.GetDec #>0 <#1         'Output the 0 or 1 to the H-Bridge chip's direction pin
    idle:= False

                                        'Call this code every 5 minutes
                                        
    if rotate == 1                      'Check whether rotation protocol has been started.
      outa[EDir]~~                      'Set Extension motor direction outward
      ArmDutyCycle:=100                   'Set Extension motor's duty cycle ** Probably want this to slow down based on encoder position as it nears the gear 

      ArmTarget:=ArmZero + 1023/12               'Set target 360/12 degrees of rotation away from current position
                                                 'Aboslute reference by using ArmZero
      repeat until ArmPosition => ArmTarget      'Extend until arm at contact position 
        'waitcnt(clkfreq*(ExtTime)+cnt) 
        if Encoder
          
      contact:=False                    'Reset limit Switch
      EDutyCycle~~                      'Turn off extension motor
      pst.NewLine
      pst.str(string("Contact!"))
      
    Flipping:=True                   'Start running ManualControl Light method
    waitcnt(cnt+clkfreq)             'Pause for motor to stop
    
    outa[HDir]~~                       'Set hourglass rotation                 
    HDutyCycle:=100                   'Set Hourglass motor duty cycle

    if HGPosition < 512                'Ideally, this is absolute.  Checks whether position is greater than the absolute position associated w/ vertical hourglass
      target := HGPosition + 512       'Sets target position to be 512 AKA 1/2 roation away from its current position
      pst.NewLine
      pst.str(string("target: "))
      pst.dec(target)

    if HGPosition > 512
      target := HGPosition - 512
      pst.NewLine
      pst.str(string("target: "))
      pst.dec(target)

    repeat until HGPosition => target           'Move until encoder reads that position has exceeded target position (if rotating clockwise)
      HGposition:= Encoder(HCLK, HCS, HSI)      'Get Hourglass position from encoder
      if ||(HGPosition - target) > 0       
        pst.NewLine
        pst.str(string("HGPosition: "))
        pst.dec(HGPosition)  


PUB Encoder(CLK, CS, SI) : PosData
dira[CLK]~~
dira[CS]~~  
dira[SI]~               'Pin 4 set to input to receive encoder data, Pins 2 and 6 set as outputs
PosData:=0 


outa[CLK]~~
outa[CS]~~
outa[CS]~
outa[CLK]~

repeat 16
   outa[CLK]~~
   PosData:=(PosData <<1)+ina[SI]    'Get position data from 16-bit Encoder value, starting with MSB                   
   outa[CLK]~  
PosData:= PosData >> 6               'Shift 6 bits to right to only use upper 10 position bits
outa[CS]~~                           'Deactivate encoder


PUB PWM(pin1, pin2) | endcnt    'This method creates a 10kHz PWM signal (duty cycle is set by the
                                ' DutyCycleVariables) clock must be 100MHz

'*** I think there's a better way to do this.

                                
  dira[pin1..pin2]~~                   'Set the direction of "pin" to be an output for this cog
  ctra[5..0]:=pin1               'Set the "A pin" of this cog's "A Counter" to be "pin"
  ctra[30..26]:=%00100          'Set this cog's "A Counter" to run in single-ended NCO/PWM mode
                                ' (where frqa always acccumulates to phsa and the 
                                '  Apin output state is bit 31 of the phsa value)                              
  ctrb[5..0]:=pin2               'Set the B pin of this cog's B Counter to be "pin2"
  ctrb[30..26]:=%00100          'Set this cog's B Counter" to run in single-ended NCO/PWM mode
  
                                                                            
  frqa:=1                       'Set counter's frqa value to 1 (1 is added to phsa at each clock) 
  frqb:=1
  endcnt:=cnt                   'Store the current system counter's value as "endcnt"                                 
  repeat                        'Repeat the following lines forever
    phsa:=-(100*EDutyCycle)      'Send a high pulse for specified number of microseconds ** 10 nanoseconds*100 = 1 microsecond
    phsb:=-(100*HDutyCycle)      'Send a high pulse for specified number of microseconds
    
    endcnt:=endcnt+10_000       'Calculate the system counter's value after 100 microseconds  
 
    waitcnt(endcnt)             'Wait until 100 microseconds have elapsed


Pub SecondHand | i, TotalTime, T1, T2, T3, T4, T5, TAll 

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
  if StartTime == True
      rgb.alloff
      repeat i from 0 to R1End 
        rgb.SetSection(R1Start, i, rgb#green) 
        waitcnt(clkfreq*T1/10+cnt)
      rgb.AllOff

  


Pub ManualControl

If Flipping == True
  rgb.alloff 
  position:= HGPosition
  rgb.LED((position/(1024/R1Len)), rgb#blue)
    if ||(position/(1024/R1Len) - PrevPosition) > 0
      rgb.LED(PrevPosition, rgb#off)
      'rgb.AllOff
      'pst.str(string("Position is:" ))
      'pst.dec((position/(1024/R1Len))) 
      'pst.NewLine
      'pst.dec(PrevPosition)            
      PrevPosition:=position/(1024/(R1Len))



'***LED SECTION***
        
Pub Int(color) : IntColor

  IntColor:= rgb.Intensity(color, MaxInt)          'Wrapper function to quickly set a max intensity value across board
   
Pub Int_Sweep | V_Int, i, j, time
 V_Int:= 0
 time:=100            'How long to fade in and out - 2 is half second
 repeat j from 0 to 8                             
  repeat i from 0 to MaxInt                   
    rgb.SetSection(R1Start,R5End,V_Int)      'Gradually fade up to max intensity
    V_Int := rgb.Intensity(Colors[j], i)     'Step through intensity - waitcnt determines how long this takes, equal time per intensity value
    waitcnt(clkfreq/time+cnt)   
  repeat i from 0 to MaxInt
    rgb.SetSection(R1Start,R5End,V_Int)         'Gradually fade down to 0 
    V_Int := rgb.Intensity(Colors[j], MaxInt-i)
    waitcnt(clkfreq/time+cnt)  
  
          
Pub Rotary_Sweep | i, j, Speed
    'rgb.SetSection(R1Start, i, rgb#orange)

    Speed:=100                                  'Time per LED step. 1 = 1 second
    repeat j from 0 to 8
      repeat i from 0 to R5End 
        rgb.SetSection(R1Start, i, Int(Colors[j])) 
        waitcnt(clkfreq/Speed+cnt)

Pub Pie  | i, j, k, q
repeat k from 0 to 14
  repeat j from 1 to 8
    
    repeat i from 0 to 4
      if i == 3
       i ++
      rgb.SetSection(RStart[i] , RStart[i] + RLen[i]/8*j , Int(Colors[k]))
         
    waitcnt(clkfreq/10+cnt)
               
Pub Target_Sweep | Speed, i, j
    Speed:=15

  repeat j from 0 to 14                                       'Loops through each of the 15 colors
    repeat i from 0 to 4                                      'Loops through each of the five rings
      rgb.SetSection(RStart[i], REnd[i], Int(Colors[j]))      'Move inwards radially
      waitcnt(clkfreq/Speed+cnt)
      rgb.SetSection(RStart[i], REnd[i], rgb#off)
      'waitcnt(clkfreq/(1000)+cnt)  
   repeat i from 0 to 4
      rgb.SetSection(RStart[4-i], REnd[4-i], Int(Colors[j]))  'Move outwards radially
      waitcnt(clkfreq/(Speed)+cnt)
      if i == 4                                               'If it's the last ring, don't end on an off command
        waitcnt(clkfreq/(100)+cnt)                             '
        quit   
      rgb.SetSection(RStart[4-i], REnd[4-i], rgb#off)
        waitcnt(clkfreq/(100)+cnt)                      