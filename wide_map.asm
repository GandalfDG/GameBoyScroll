
INCLUDE "gbhw.inc" ;hardware definitions
INCLUDE "tiles.z80" ;tile data for Free Runner
INCLUDE "wide_map.z80" ;map data for level 1

MapOFST EQU $FF80 ;value to add when loading 32 tile width during init
NextCLM EQU $FF81 ;number of the next column
TileScrollCNT EQU $FF82 ;count of how many tiles have passed - basically Scroll register / 8
VBlankCount EQU $FF83
;interrupts
SECTION	"Vblank",HOME[$0040]
	ld a, [rSCX]													
	inc a
	ld [rSCX], a ;advance window 1 pixel per VBlank
	ld a, [VBlankCount]
	cp 0 
	jp NZ, .decrease ;if not zero, jump and decrease it
	ld a, 7 ;else vblankcount = 7
	ld [VBlankCount], a
	ld a, [TileScrollCNT]
	inc a
	ld [TileScrollCNT], a
	reti
.decrease
	dec a
	ld [VBlankCount], a
	reti		
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
	sub a, 32
	ld [MapOFST], a
	
	ld a, 0
	ld [rSCX], a    ;set BG scroll X&Y to 0
	ld [rSCY], a
	ld [TileScrollCNT], a ;0 tiles scrolled at init
	ld [VBlankCount], a
	call stopLCD
	
	ld hl, TileLabel ;load in tile data
	ld de, _VRAM
	ld bc, 16*22
	call mem_Copy
	ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF ;turn the screen back on
	ld [rLCDC], a
	
	call loadBG
	
	ld a, 32
	ld [NextCLM], a	
	
	
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

;loads the first 32 columns of the map regardless of map length	
loadBG:
	ld a, 18 ;loop counter
	ld hl, LevelMap ;initial map location
	ld de, _SCRN0 ;start of BG RAM
	
.loop
	ld bc, 32 ;load 32 bytes
	push af
	call mem_CopyVRAM ;copy first 32 bytes of map into VRAM
	ld a, [MapOFST]
	ld c, a
	add hl, bc ;move to next row of map
	pop af
	dec a ;decrease the loop counter
	jr nz, .loop ;jump back to .loop unless decreasing af sets Zero flag
	ret ;return


loadNextCLM:
	ld a, [rSCX] ;get current window location
	 
	;if [rSCX] = 0 load the next column into 
	
