;
; UnderwaterDiamondGame.asm
; Created: 11-03-24 12:23:39 AM
; Author : Shola

.include "m328pdef.inc" ; Load addresses of (I/O) registers
.ORG 0x0000 ; Set the origin address to 0x0000
    RJMP init  ; First instruction that is executed by the microcontroller
.ORG 0x0020 ; Point to The interrupt handler {timer0 overflow}
    RJMP Timer0OverflowInterrupt

.include "simpleMacro.inc"
.include "FlashAddr.inc"

;====================== Constants Definitions====================================
.equ toPsc           = 0b00000100 ; prescaler 256
.equ ENABLE_INTERRUPT= 0b00000001 ; enable interrupt 
.equ OUTPUT_MASK     = (1 << PB3) | (1 << PB4) | (1 << PB5) ; Constants for setting PB3, PB4, and PB5 as outputs 

; f_clk=16MHz/256
;TCNT_init=256-(f_clk/880)=185 
.equ SETT0           = 185 ; set timer0 init 185
.equ flashStartAddress=0x0100
.equ blocks         = 16 ; 0-->15
.equ Diamond        = 0 ; hidden diamond to search for
.equ game_counter            = 5 ; compare counter value limit
;============= Register Definition=============
.DEF rmp = R16            ; Multipurpose temporary register

;===============================================================================
;      PIN initialization
;===============================================================================
init:
    CBI DDRB,0 ; Pin PB0 is an input {the switch} 
    SBI PORTB,0  ; Enable the pull-up resistor to avoid input floating
    SBI DDRC, 2; Pin PC2 is an output {top LED} {LED1}, Output Vcc => LED1 is turned off! 
	SBI PORTC,2 ; Output Vcc => LED1 is turned off!
    SBI DDRB,3 ; Pin PC3 is an output {bottom LED} {LED2}
	SBI PORTC,3

;===============================================================================
;                GAME CLOCK CONFIGURATION (Timer0)
;===============================================================================
    LDI R17, (1 << CS01) | (1 << CS00) ; { 0b00000100 } prescaler 256
    OUT TCCR0B, R17
    LDI R20, ENABLE_INTERRUPT
    STS TIMSK0, R20 ; set the first bit of this register to 1 so that we enable timer0 overflow interrupt . OUT TIMSK0, R20 did not work neither did mov instruction worked i.e mov TIMSK0, R20
    LDI R28, SETT0
    STS TCNT0, R28 ; Set timer0 initial value
	 SEI
    rjmp GameScreen ; Go to Game home page 

;===============================================================================	
;                          MAIN STARTS
;===============================================================================
main:
;==============================================================================
;SWITCH CONTROL
;==============================================================================
    IN R0, PINB ; Read the value from the input port B into register R0
    BST R0, 0  ; and Copy PB0 to the T flag
    BRTS Switch_high ;jump to Switch_high if toogle  flag is set { The switch is high if the Toggle  flag is set}
    LDI R17, 0b00000000 ; interrupt off if  toggle flag is not set (switch is low) and load immediate value 0b00000000 
    STS TIMSK0, R17
    RJMP Keyboard
FakeLow:
    ;SBI PORTC, 2 ; Turn off LED1
    RJMP main  ; Create an infinite loop
Switch_high:
    LDI R17, 0b00000001 ; interrupt on
    STS TIMSK0, R17
    RJMP Keyboard	
		
;==============================================================================
;                                KEYBOARD
;==============================================================================
; Store switch number (cfr docs) in R18 => (row-1)*4 + col
; activate pull up resistors. PD3, PD2, PD1, PD0 - input columns
keyboard:
    SBI PORTD, 3 ; Enable the pull-up resistor
    SBI PORTD, 2 ; Enable the pull-up resistor
    SBI PORTD, 1 ; Enable the pull-up resistor
    SBI PORTD, 0 ; Enable the pull-up resistor

    CBI DDRD, 3     ; Y==>COLUMN 3-->0 INPUT set to 0
    CBI DDRD, 2	    ; Pin PD2 is an input
    CBI DDRD, 1		; Pin PD1 is an input
    CBI DDRD, 0		; Pin PD0 is an input

    ; PD7, PD6, PD5, PD4 -  X==>ROW 7-4  OUTPUT rows are low
    SBI DDRD, 7 ; Pin PD7 is an output
    SBI DDRD, 6  ; Pin PD6 is an output
    SBI DDRD, 5 ; Pin PD5 is an output
    SBI DDRD, 4 ; Pin PD4 is an output

; Detect the key pressed
; start Row7Low_Step1 scan columns 3 to 0 and ground row 7.
; PD7: step1 iterate over columns 3 to 0 while grounding output 7.
    nop         ; a cycle to make sure the output is stable 
    CBI PORTD, 7 ; read first row
    SBI PORTD, 6
    SBI PORTD, 5
    SBI PORTD, 4
    nop             
	nop                
	; check PD3,2,1,0 if cleared
	; skip if bit in I/O register set
	nop
	SBIS PIND, 0  ; checking the 1st column  and  skip the next instruction if no button is pressed in this column
	RJMP Key_F   ; Jump to corresponding section if a button 0 is pressed
	SBIS PIND, 1 ; checking the 2nd column 
	RJMP Key_9 ; if PD1 is cleared, column 1 is pressed
	SBIS PIND, 2 ; checking the 3rd column
	RJMP Key_8; if PD2 is cleared, column 2 is pressed
	SBIS PIND, 3; checking the 4th column 
	RJMP Key_7; if PD3 is cleared, column 3 is pressed
	nop
	; PD6(Row6Low_): step2 iterate over columns 3 to 0 while grounding output 6.
	SBI PORTD, 4
	SBI PORTD, 5
	CBI PORTD, 6
	SBI PORTD, 7
	nop
	nop
	; check PD3,2,1,0 if cleared
	; skip if bit in I/O register set
	nop     ; a cycle to make sure the output is stable 
	SBIS PIND, 0
	RJMP Key_E
	SBIS PIND, 1
	RJMP Key_6
	SBIS PIND, 2
	RJMP Key_5
	SBIS PIND, 3
	RJMP Key_4
	; PD5(Row5Low): step3 iterate over columns 3 to 0 while grounding output 5.
	nop
	SBI PORTD, 4
	CBI PORTD, 5
	SBI PORTD, 6
	SBI PORTD, 7
	; check PD3,2,1,0 if cleared
	; skip if bit in I/O register set
	nop
	nop
	SBIS PIND, 0
	RJMP Key_D
	SBIS PIND, 1
	RJMP Key_3
	SBIS PIND, 2
	RJMP Key_2
	SBIS PIND, 3
	RJMP Key_1  
	; PD4 (Row4Low): step4 iterate over columns 3 to 0 while grounding output 4.
	CBI PORTD, 4
	SBI PORTD, 5
	SBI PORTD, 6
	SBI PORTD, 7
	nop
	; check PD3,2,1,0 if cleared
	; skip if bit in I/O register set
	SBIS PIND, 0
	RJMP Key_C
	SBIS PIND, 1
	RJMP Key_B
	SBIS PIND, 2
	RJMP Key_0
	SBIS PIND, 3
	RJMP Key_A
	RJMP GameKeyCheck
	Key_0:
		LDI rmp, 0
		LDI R25, 0  ; to know may be a  key is  pressed
		RJMP main
	Key_1:
		LDI rmp, 1
		LDI R25, 0 ; to know  may be a  key is  pressed
		RJMP main
	Key_2:
		LDI rmp, 2
		LDI R25, 0
		RJMP main
	Key_3:
		LDI rmp, 3
		LDI R25, 0
		RJMP main
	Key_4:
		LDI rmp, 4
		LDI R25, 0
		RJMP main
	Key_5:
		LDI rmp, 5
		LDI R25, 0
		RJMP main
	Key_6:
		LDI rmp, 6
		LDI R25, 0
		RJMP main
	Key_7:
		LDI rmp, 7
		LDI R25, 0
		RJMP main
	Key_8:
		LDI rmp, 8
		LDI R25, 0
		RJMP main
	Key_9:
		LDI rmp, 9
		LDI R25, 0
		RJMP main
	Key_A:
		LDI rmp, 10
		LDI R25, 0
		RJMP main
	Key_B:
		LDI rmp, 11
		LDI R25, 0
		RJMP main
	Key_C:
		LDI rmp, 12
		LDI R25, 0
		RJMP main
	Key_D:
		LDI rmp, 13
		LDI R25, 0
		RJMP main
	Key_E:
		LDI rmp, 14
		LDI R25, 0
		RJMP main
	Key_F:
		LDI rmp, 15 ; detect may be a key is pressed and which object is loaded by comparing the value of R25
		LDI R25, 0
		RJMP main
	GameKeyCheck:
		CPI R25, 1 ; for check when  no key is  pressed 
		BREQ loop
		RCALL keyPadPressed
		RJMP GameKeyCheck
	loop:
		RJMP main

;===============================================================================			 
;                        Game Logic
;===============================================================================
keyPadPressed:
    STD Y+8, rmp ; store the value from Y to register rpm  and  display the key  pressed  
    INC R18 ; counter increament
    CPI R18, game_counter ; check maybe compared times in R18 has increased up to 4 
    BREQ limitReached ; if true  then  go the  next  instrcution "limitReached"
    STD Y+15, R18;  

    LDI R25, 1 ; to check if  keypad is not pressed
    CP rmp, R19  ; checking if key pressed matches hidden diamond object
    BREQ GameTokenFound    ; Display FOUND message because the diamond object is gotten
    RJMP GameTokenMissed   ; Continue normally until  the  diamond  is found or  miss
; If the counter reaches the limit of 4, restart the process
limitReached:
RJMP resetCounter

;===========================================================================
;       DISPLAY FOUND OR TRY AGAIN
;===========================================================================
resetCounter:
RJMP init  
GameTokenFound:
	nop
	CBI PORTC, 2
	sbi PORTC,3
    LDI R17, 24  ; write the value at address 21 into register R17
    MOV R6, R17  ;  copy the value in R17 to R6
    STD Y+11, R6 ; write to cell 3 above SRAM_START central  location 
    LDI R17, 24 
    MOV R7, R17
    STD Y+12, R7
    LDI R17, 24
    MOV R8, R17
    STD Y+13, R8
    LDI R17, 25 
    MOV R9, R17
    STD Y+14, R9
    LDI R17, 0x0;  intialize  delay
    RCALL loop1 ; Call subroutine
    RJMP init   ; Jump back to init after subroutine execution
loop1:
    nop
    LDI rmp, 0x01
loop2:
    nop
    nop
    LDI R19, 200
loop3:
    nop
    nop
    nop
    INC R19
    BRNE loop3
    INC rmp
    BRNE loop2
    INC R17
    BRNE loop1
    RJMP init   
	GameTokenMissed:			
			LDI R17, 19 ; T charachter buffer index
			MOV R2,R17
			STD Y+11, R2 
			LDI R17, 17 ; R charachter buffer index
			MOV R3,R17  
			STD Y+12, R3 
			LDI R17, 26 ; Y charachter buffer index
			MOV R4,R17
			STD Y+13, R4
			LDI R17, 25 ; empty charachter buffer index
			MOV R5,R17
			STD Y+14, R5
			INC R19   ; hidden Diamond no +1 for every GameTokenMissed
	       RJMP main

; Output Enable/Latch CLK (PB4) is output
; Clock (PB5) is output
; Data In (PB3) is output
GameScreen:
    ; Initialize DDRB to set PB3, PB4, and PB5 as outputs
    LDI R17, OUTPUT_MASK   
    OUT DDRB, R17
    ; Set PORTB to a specific value
    LDI R17, 0b11000111
    OUT PORTB, R17
    ; GAME REGISTERS INITIALIZATION
    LDI R18, 0x01   ; game counter
    LDI R25, 1        ; check if keyboard was pressed
    LDI R19, Diamond    ; hidden Diamond no

	;==================================================================
	;  PRESET REGISTERS FOR SCREEN INTERRUPT
    ;==================================================================
    CLR rmp
    CLR R18
    CLR R19
    CLR R20
    CLR R21
    CLR R22
    CLR R23
    CLR R24
    CLR R28

;=======================================================================
;                          GAME HOME DISPLAY=
;=====================================================================
; Char initialization in blocks
LDI YH, high(flashStartAddress) ;Set the MSB of the address
LDI YL, low(flashStartAddress) ; Set the LSB of the address
LDI R17, 20 ; S charachter buffer index
ST Y, R17
LDI R17, 14 ; E charachter buffer index  
STD Y+1, R17; Store the MSB  to  SRAM location with displacement of 1
LDI R17, 10  ; A charachter buffer index
STD Y+2, R17 ;adds temporarily a 2 to Y  and  writes the character S  to  SRAM.
LDI R17, 17  ; R charachter buffer index
STD Y+3, R17;adds temporarily a 3 to Y  and  writes the character S  to  SRAM.
LDI R17, 12   ; C charachter buffer index
STD Y+4, R17
LDI R17, 16   ; H charachter buffer index
STD Y+5, R17
LDI R17, 25   ; blank charachter buffer index
STD Y+6, R17
LDI R17, 24   ; 0 charachter buffer index
STD Y+7, R17
; second pattern
LDI R17, 25   ; 
STD Y+8, R17
LDI R17, 25   ;space
STD Y+9, R17
LDI R17, 25   ;space
STD Y+10, R17
LDI R17, 25   ;space 
STD Y+11, R17
LDI R17, 25   ;space 
STD Y+12, R17
LDI R17, 25   ;space
STD Y+13, R17
LDI R17, 25   ;space
STD Y+14, R17
LDI R17, 0    
STD Y+15, R17
RJMP main

;========================================================================
;              SCREEN CONFIGURATION {Fill  in order of display}

; We use Timer0 to refresh the screen. This function reads the pixel values from the flash memory and put the 
; corresponding data into the screen's shift registers
; Loop for all columns and the corresponding row (88 bits)
;========================================================================

Timer0OverflowInterrupt:
    PUSH R17  ; Throw the value in R17 on top of the stack
	PUSH YH
	PUSH YL
	PUSH ZH
	PUSH ZL
    LDI R17, SREG ; save register on stack
    ; GameKeyCheck timer counter 
    LDI R28, SETT0   ; Set timer 0 counter=185 for prescaler, Freq=880Hz
    OUT TCNT0, R28
    ; Each block with column config  
    LDI R22, blocks  ; Because we have 16 displays 
	; Loop for all columns and the corresponding row (88 bits)
BlockColLoop:
	;=============================================================
	; This function fills the screen data memory with a byte  (= repeat a pattern on the screen)
    ; Init character pointer
	; R22: Data byte pattern
	;=============================================================
    LDI YH, high(flashStartAddress) ; Resetting byte2 of Y  { Load the MSB of address}
    LDI YL, low(flashStartAddress) ; Resetting byte1 of Y {Load the LSB of address}
    ADD YL, R22 ; Point to correct block
    LD R27, Y  ; Load the corresponding value of the block from the character buffer (SRAM)  

	;================================================================
	; Write a Word (multiple characters) on the screen (SRAM)
    ; Init JmpTable character pointer and pass the value of the columns to one block in FLASH MEMORY
	; least significant bit selects the lower or upper byte (0=lower byte, 1= upper byte). Because of this the original address must be multiplied by 2
    ;===============================================================
	LDI ZH, high(JmpTable<<1); address of JmpTableto pointer Z  multiplied by 2 for bytewise access
    LDI ZL, low(JmpTable<<1)  ; Load address JmpTable into flash memory using Z pointer (R31) byte1 ( multiplied by 2 for bytewise access)
    
	ADD R27, R27  ; Shift left to move to the next row  {address must be incremented to point to the next byte in program memory by left shifting to i.e  x2} 
    ADD ZL, R27 ; Point to the address of the correct JmpTable and to correct the address (multiplying by 8 because the assembler expects the lower of the pointer register pair ZL as first parameter
    CLR R1	; Clear carry for overflows
    ADC ZH, R1  ; If there is a carry add one to ZH { Add the MSB because STD does not affect SREG }

	LPM R21, Z+  ; byte1 {Read least significant byte from program memory and  copies the byte from program memory { flash address} Z to the SRAM register R21} 
	LPM R24, Z+  ; byte2 { read, Point to MSB in program memory,  copies the byte at program flash address Z to the SRAM register R21} 
    MOV ZL, R21	 ; Copy LSB to 8-bit  out of 16 bit pointer register
    MOV ZH, R24	 ; Copy MSB to 8-bit  out of 16 bit pointer register
    CLR R1
	;Add two 8 bits in R20 and R1 to the result, with overflow from LSB to MSB
	ADD ZL, R20  ; add row offset
	ADC ZH, R1  ; add carry and MSB of R1
	LPM R27, Z  

    ; The column configuration for a block because we have 5 columns in our displays
    GameCol 0     	
    GameCol 1
    GameCol 2
    GameCol 3
    GameCol 4  
    SUBI R22, 1 ; Decrement R22
    BRSH BlockColLoop ; Branch if R22 is not negative (i.e., higher or same)

    SBI PINB,3 ; Carry is one and send zero if we don't have carry  to  send the bits to be written to the AVR
    SBI PINB,5 ; To generate a clock signal, need flip it twice, first for rising edge, second for falling edge {A clock signal that shifts the bits to be written to the memory into an internal shift register, and
			   ;that shifts out the bits to be read from another internal shift register,}
    SBI PINB,5
    nop
    nop

; Row configuration, we need to pass the values of the rows
SendRowLoop:
    GameRow 6
    GameRow 5
    GameRow 4
    GameRow 3
    GameRow 2
    GameRow 1
    GameRow 0
    DEC R20
    LSR R23 ; The LSB goes first to the carry

    TST R23	;  all bits zero? ; Null termination? {if the Z-bit is set, the register R23 is zero } 
    BRNE GameDelay	; if not, go on in the loop  by introducing some delays
    LDI R23, 0x40  ; Re-initialize row 
    LDI R20, 0x06   ; An offset of 6 

; Delay is needed in order for the LEDs to be cleared
GameDelay:
    CALL DelayLoop1
    CALL DelayLoop2
    CALL DelayLoop3
    SBI PINB,4  ; Output enable
    OUT SREG, R17; Deactivate interrupt machinery { restore flags  old status}
	POP ZL
	POP ZH
	POP YL
	POP YH
    POP R17   ;Read back the value  in R17 from the top of the stack{ Because R17 is used in another place in the code }
    RETI ; return from interrupt 

LDI R22, 185   ; For GameDelay
DelayLoop1:
    DEC R22
    BRNE DelayLoop1
    RET        
DelayLoop2:
    nop ; A cycle to make sure the output is stable 
    nop
    nop
    nop
    RET    
DelayLoop3:
    SBI PINB,4 ;data latch {The data signal that receives the bits read from the AVR}
    RET
;==================================== Z ADDRESS  POINTER  FOR SCREEN====================================
    Char_A:      .db 0b00001110, 0b00010001, 0b00010001, 0b00011111, 0b00010001, 0b00010001, 0b00010001, 0b00000000;dw Char_A<<1:10
    Char_B:      .db 0b00000000, 0b00001110, 0b00011111, 0b00011111, 0b00011111, 0b00001110, 0b00000000, 0b00000000;dw Char_B<<1:11 
    Char_C:      .db 0b00001110, 0b00010000, 0b00010000, 0b00010000, 0b00010000, 0b00010001, 0b00001110, 0b00000000;dw Char_C<<1:12
    Char_D:      .db 0b00000000, 0b00001000, 0b00001100, 0b00001110, 0b00001100, 0b00001000, 0b00000000, 0b00000000;dw Char_D<<1:13 
    Char_E:      .db 0b00011111, 0b00010000, 0b00010000, 0b00011110, 0b00010000, 0b00010000, 0b00011111, 0b00000000;dw Char_E<<1:14
    Char_F:      .db 0b00011111, 0b00010000, 0b00010000, 0b00011110, 0b00010000, 0b00010000, 0b00010000, 0b00000000;dw Char_F<<1:15
    Char_H:      .db 0b00010001, 0b00010001, 0b00010001, 0b00011111, 0b00010001, 0b00010001, 0b00010001, 0b00000000;dw Char_H<<1:16
    Char_R:      .db 0b00011110, 0b00010001, 0b00010001, 0b00011110, 0b00010001, 0b00010001, 0b00010001, 0b00000000;dw Char_R<<1:17
    Char_I:      .db 0b00001110, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00001110, 0b00000000;dw Char_I<<1:18
    Char_T:      .db 0b00011111, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000000;dw Char_T<<1:19
    Char_S:      .db 0b00001110, 0b00010001, 0b00010000, 0b00011110, 0b00000001, 0b00010001, 0b00001110, 0b00000000;dw Char_S<<1:20
    Char_U:      .db 0b00010001, 0b00010001, 0b00010001, 0b00010001, 0b00010001, 0b00010001, 0b00001110, 0b00000000;dw Char_W<<1: 21
    Char_N:      .db 0b00010001, 0b00011001, 0b00010101, 0b00010010, 0b00010001, 0b00010001, 0b00010001, 0b00000000;dw Char_N<<1:22
    Char_O:      .db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000;dw Char_O<<1: 23  
    Char_0:      .db 0b00001110, 0b00010001, 0b00010011, 0b00010101, 0b00011001, 0b00010001, 0b00001110, 0b00000000;dw Char_0<<1:0
    Char_1:      .db 0b00000100, 0b00001100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00001110, 0b00000000;dw Char_1<<1
    Char_2:      .db 0b00001110, 0b00010001, 0b00000001, 0b00000010, 0b00000100, 0b00001000, 0b00011111, 0b00000000 ;dw Char_2<<1 
    Char_3:      .db 0b00001110, 0b00010001, 0b00000001, 0b00000110, 0b00000001, 0b00010001, 0b00001110, 0b00000000;dw Char_3<<1
    Char_4:      .db 0b00000010, 0b00000110, 0b00001010, 0b00010010, 0b00011111, 0b00000010, 0b00000010, 0b00000000;dw Char_4<<1
    Char_5:      .db 0b00000000, 0b00000100, 0b00001110, 0b00011111, 0b00001110, 0b00000100, 0b00000000, 0b00000000;dw Char_5<<1 
    Char_6:      .db 0b00000100, 0b00000110, 0b00000101, 0b00000101, 0b00001101, 0b00011000, 0b00011000, 0b00000000;dw Char_6<<1
    Char_7:      .db 0b00000000, 0b00000010, 0b00000110, 0b00001110, 0b00000110, 0b00000010, 0b00000000, 0b00000000;dw Char_7<<1 
    Char_8:      .db 0b00000000, 0b00000100, 0b00010101, 0b00001110, 0b00010101, 0b00000100, 0b00000000, 0b00000000;dw Char_8<<1 
    Char_9:      .db 0b00001100, 0b00010010, 0b00010100, 0b00001000, 0b00010101, 0b00010010, 0b00001101, 0b00000000;dw Char_9<<1
    Char_dot:    .db 0b00000000, 0b00001110, 0b00011111, 0b00010001, 0b00001010, 0b00000100, 0b00000000, 0b00000000;dw Char_dot<<1:24
    Char_Space:  .db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000;dw Char_Space<<1: 25
    Char_Y:      .db 0b00010001, 0b00010001, 0b00010001, 0b00001010, 0b00000100, 0b00000100, 0b00000100, 0b00000000;dw Char_Y<<1: 26
	Char_Q:		 .db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000;.dw Char_Q<<1:27  

	
	

