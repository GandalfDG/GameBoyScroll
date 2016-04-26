;knack
INCLUDE "gbhw.inc" ;hardware definitions
INCLUDE "tiles.z80" ;tile data for Free Runner
INCLUDE "screen1.z80" ;map data for level 1
SCRSPD	EQU	25
;interrupts
SECTION	"Vblank",HOME[$0040]
	ld a, [rSCX]													
	inc a
	ld [rSCX], a
	
SECTION	"LCDC",HOME[$0048]
	reti
SECTION	"Timer_Overflow",HOME[$0050]
	reti
SECTION	"Serial",HOME[$0058]
	reti
SECTION	"p1thru4",HOME[$0060]
	reti
	
SECTION "start",ROM0[$0100] ;where the gameboy starts reading user code
	nop
	jp begin


	ROM_HEADER	ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE
INCLUDE "memory.asm"


begin:
	di
	ld sp,$ffff
	
init:
	ld a, %11100100 ;default palette
	ld [rBGP], a    ;load into background palette RAM
	
	ld a, LevelMapWidth
	sbc a, 32
	ld [$ff80], a
	
	ld a, 0
	ld [rSCX], a    ;set BG scroll X&Y to 0
	ld [rSCY], a
	call stopLCD
	ld hl, TileLabel
	ld de, _VRAM
	ld bc, 16*22
	call mem_Copy
	ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF ;turn the screen back on
	ld [rLCDC], a
	
	ld	a, 19		
	ld	hl, _SCRN0
	ld	bc, SCRN_VX_B * SCRN_VY_B
	call	mem_SetVRAM
	
	ld hl, LevelMap
	ld de, _SCRN0
	ld bc, 1088
	call mem_CopyVRAM
	;KNACK Ladies and Gentlemen
	
	ld a, %00000001  ;enable vblank interrupt
	ld [$ffff], a
	
	ei ;enable interrupts, vblank will cause horizontal scrolling
	
 

wait:
	halt
	nop
	jr	wait
	
	
stopLCD:
	ld a, [rLCDC]
	rlca
	ret nc ;screen is already off
	
.wait:  ;wait for vblank to turn off screen
	ld a, [rLY]
	cp 145
	jr nz, .wait
	
	ld a, [rLCDC]
	res 7, a  ;set LCD to off
	ld [rLCDC], a
	ret


	

	
