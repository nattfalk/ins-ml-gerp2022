	rasterline1 = 0
	rasterline2 = 118
	rasterline3 = 242

	!address{
		characterindex = $64
		rowindex = $65
		cursorcolorindex = $66
		delayindex = $67
		colormempointer = $80
		screenmempointer = $82
		textcolorpointer = $84
		textpointer = $86
		screenmem = $0400
		textscreenmem = screenmem + 10 * 40
		line1 = screenmem + 9 * 40
		line2 = screenmem + 23 * 40
		sid = $1000
		sidplay = $1003
		logobitmap = $2000
		logocolors = $3000
		logoscreen = $33eb
		charset = $3800
		sprites = $3e00
		textcolors = $4000
		linecolors = $4281
		cursorcolors = $42aa
		spriteposx = $4310
		spriteposy = $4320
		spritespeed = $4330
		text = $4440
		spritesposmem = $d000
		colormem = $d800
		line1colormem = colormem + 9 * 40
		line2colormem = colormem + 23 * 40
		textcolormem = $d990
	}

	*= $0801

	jsr $e544

	lda #$00
	sta $d020
	sta $d021

	;lda #$7f
	lda #$32
	sta delayindex
	
	jsr sid
	jsr initsprites
	jsr setspritepointers
	jsr resetpointers
    jsr logo
    jsr horizontallines
    jsr main

logo:
	ldx #$00
-
	lda logocolors,x
	sta colormem,x

	lda logoscreen,x
	sta screenmem,x

	inx
	bne -

	ldx #$00
-
	lda logocolors + 256,x
	sta colormem + 256,x

	lda logoscreen + 256,x
	sta screenmem + 256,x

	inx
	cpx #$40
	bne -
	rts

horizontallines:
	ldx #$00
-
	lda #$63
	sta line1,x
	sta line2,x

	inx
	cpx #40
	bne -
    rts

main:
	sei

	lda #%00110101
	sta $01

	lda #%01111111
	sta $dc0d
	sta $dd0d

	lda #%00000001
	sta $d01a

	lda #rasterline1
	sta $d012

	lda #<gfxirq 
	sta $fffe
	lda #>gfxirq
	sta $ffff

	cli

	jmp *

gfxirq:
	asl $d019

	lda #%00111011
	sta $d011

	lda #%00011000
	sta $d016

	lda #%00011110
	sta $d018
	
	jsr sidplay
	jsr starfield

	lda #rasterline2
	sta $d012

	lda #<txtirq
	sta $fffe
	lda #>txtirq
	sta $ffff
	rti
	
txtirq:
	asl $d019

	lda #%00011011
	sta $d011

	lda #%11001000
	sta $d016

	lda #%00011110
	sta $d018

	jsr colorcycle
	jsr textwriter

	lda #rasterline3
	sta $d012

	lda #<scrollirq
	sta $fffe
	lda #>scrollirq
	sta $ffff

	rti

scrollirq:
	asl $d019

	jsr textscroller
	
	lda $d016
	and #248
	adc offset
	sta $d016

	lda #rasterline1
	sta $d012

	lda #<gfxirq
	sta $fffe
	lda #>gfxirq
	sta $ffff
	rti

textscroller:

	dec smooth
	bne continue

	dec offset
	bpl resetsmooth
	lda #07
	sta offset

shiftrow:
	ldx #00
-	lda $07c1, x
	sta $07c0, x
	inx
	cpx #39
	bne -

	ldx nextchar
	lda scrolltext, x
	sta $07e7			
	inx
	lda scrolltext, x
	cmp #$ff
	bne resetsmooth-3
	ldx #00
	stx nextchar

resetsmooth:
	ldx #01
	stx smooth
	rts

continue:	
	rts

starfield:
	ldx #$00
-
	lda spriteposy,x
	sta spritesposmem + 1,x

	lda spriteposx,x
	asl
	ror $d010
	sta spritesposmem,x

	lda spriteposx,x
	clc
	sbc spritespeed,x
	sta spriteposx,x

	inx
	inx
	cpx #$10
	bne -
	rts

colorcycle:
	lda linecolors
	sta linecolors + 40

	ldx #$00
-	lda linecolors + 1,x
	sta linecolors,x
	sta line1colormem,x
	sta line2colormem,x
	adc #10
	sta line2colormem + 40,x

	lda #$00
	sta line2colormem + 40
	sta line2colormem + 41
	sta line2colormem + 78
	sta line2colormem + 79

	inx
	cpx #40
	bne -
	rts

textwriter:
	lda cursorcolorindex
	cmp #19
	beq resetcursorcolor

	inc cursorcolorindex

	lda delayindex
	cmp #$00
	beq dotext
	bcs pause
	rts

pause:
	jsr writecursor

	dec delayindex

	lda delayindex
	cmp #$00
	beq clearscreen
	rts

clearscreen:
	lda #$20
	ldx #$00
-
	sta textscreenmem,x
	sta textscreenmem + 255,x

	inx
	;cpx #$ff
	bne -

	ldx #$00
-
	sta textscreenmem + 255 * 2,x

	inx
	cpx #10
	bne -

	jsr clearindices
	jsr setcolorpointer
	jsr settextcolorpointer
	jsr setscreenpointer
	rts

dotext:
	jsr writecharacter
	jsr writecursor
	rts

resetcursorcolor:
	lda #$00
	sta cursorcolorindex
	rts

writecursor:
	ldx cursorcolorindex
	ldy characterindex
	lda cursorcolors,x
	sta (colormempointer),y

	lda #$7f
	sta (screenmempointer),y
	rts

writecharacter:
	ldy characterindex
	lda (textcolorpointer),y
	sta (colormempointer),y

	lda (textpointer),y
	cmp #$ff
	beq resetpointers

	sta (screenmempointer),y

	cpy #39
	beq nextrow

	inc characterindex
	rts

pushoffsets:
	clc

	lda colormempointer
	adc #40
	sta colormempointer
	lda colormempointer + 1
	adc #$00
	sta colormempointer + 1

	lda textcolorpointer
	adc #40
	sta textcolorpointer
	lda textcolorpointer + 1
	adc #$00
	sta textcolorpointer + 1

	lda screenmempointer
	adc #40
	sta screenmempointer
	lda screenmempointer + 1
	adc #$00
	sta screenmempointer + 1
	rts

pushoffsets2:
	clc

	lda textpointer
	adc #40
	sta textpointer
	lda textpointer + 1
	adc #$00
	sta textpointer + 1
	rts

nextrow:
	jsr pushoffsets2

	lda rowindex
	cmp #12
	beq nextscreen

	jsr pushoffsets

	lda #$00
	sta characterindex

	inc rowindex
	rts

nextscreen:
	;lda #$ff
	lda #$7f
	sta delayindex
	rts

resetpointers:
	jsr clearindices
	jsr setcolorpointer
	jsr setscreenpointer
	jsr settextcolorpointer
	jsr settextpointer
	rts

clearindices:
	lda #$00
	sta characterindex
	sta rowindex
	sta cursorcolorindex
	rts

setcolorpointer:
	lda #<textcolormem
	sta colormempointer
	lda #>textcolormem
	sta colormempointer + 1
	rts

setscreenpointer:
	lda #<textscreenmem
	sta screenmempointer
	lda #>textscreenmem
	sta screenmempointer + 1
	rts

settextcolorpointer:
	lda #<textcolors
	sta textcolorpointer
	lda #>textcolors
	sta textcolorpointer + 1
	rts

settextpointer:
	lda #<text
	sta textpointer
	lda #>text
	sta textpointer + 1
	rts

initsprites:
	lda #%11111111
	sta $d015
	sta $d01b

	lda #%00000000
	sta $d017
	sta $d01c
	sta $d01d

	lda #$01
	sta $d027

	lda #$06
	sta $d028

	lda #$0c
	sta $d029

	lda #$07
	sta $d02a

	lda #$01
	sta $d02b

	lda #$06
	sta $d02c

	lda #$0c
	sta $d02d

	lda #$07
	sta $d02e
	rts

setspritepointers:
	lda #$f8
	sta $07f8
	lda #$f9
	sta $07f9
	lda #$fa
	sta $07fa
	lda #$f8
	sta $07fb
	lda #$f9
	sta $07fc
	lda #$fa
	sta $07fd
	lda #$f8
	sta $07fe
	lda #$f9
	sta $07ff
	rts

	*= sid
	!binary "data/Glitter_in_the_Dark.sid",,$7e

	*= logobitmap
	!binary "data/logo.kla",2560,2

	*= logoscreen
	!binary "data/logo.kla",320,8002

	*= logocolors
	!binary "data/logo.kla",320,9002

	*= charset
	!source "data/charset.dat"

	*= sprites
	!source "data/sprites.dat"

	*= textcolors
	;Packs well
	!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!byte $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
	!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b

	*= linecolors
	!byte $0b,$0b,$0b,$0b,$0c,$0c,$0c,$0c,$0f,$0f,$05,$05,$07,$07,$03,$03,$01,$01,$01,$01,$01,$01,$01,$01,$03,$03,$07,$07,$05,$05,$0f,$0f,$0c,$0c,$0c,$0c,$0b,$0b,$0b,$0b

	*= cursorcolors
	!byte $00,$00,$0b,$02,$02,$04,$04,$0a,$0a,$0a,$01,$0a,$0a,$04,$04,$02,$02,$0b,$00,$00

	*= spriteposx
	!byte 30
	!byte $00
	!byte 60
	!byte $00
	!byte 90
	!byte $00
	!byte 120
	!byte $00
	!byte 150
	!byte $00
	!byte 180
	!byte $00
	!byte 210
	!byte $00
	!byte 240

	*= spriteposy
	!byte 130
	!byte $00
	!byte 150
	!byte $00
	!byte 165
	!byte $00
	!byte 180
	!byte $00
	!byte 195
	!byte $00
	!byte 200
	!byte $00
	!byte 210
	!byte $00
	!byte 220

	*= spritespeed
	!byte $01
	!byte $00
	!byte $00
	!byte $00
	!byte $01
	!byte $00
	!byte $01
	!byte $00
	!byte $02
	!byte $00
	!byte $01
	!byte $00
	!byte $01
	!byte $00
	!byte $00

	*= text
	!source "data/screens.dat"	
	!byte $ff

offset:
	!byte 07
smooth:
	!byte 01
nextchar:
	!byte 00
scrolltext:
	!source "data/scrolltext.dat"	
	!byte $ff
