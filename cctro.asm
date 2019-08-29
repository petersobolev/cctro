; CCtro - 256 bytes intro for Fairchild Channel F by Frog
; frog@enlight.ru
; https://enlight.ru/roi
; 
; p.s. thanks to http://channelf.se/veswiki people

	processor f8

clrscrn	= $00d0		; uses r31
delay	= $008f
drawchar = $0679	; prints char r0 (code+color) at col r1, row r2

xc0 = 29	; chars x0
yc0 = 27	; chars y0 

	org	$800

cartridgeStart:
	.byte	$55, $2B		; cartridge header

cartridgeEntry:

	li	$c6			; $21 - b/w palette, fill with black. $c6 - color palette, fill with gray
	lr	3, A
	pi	clrscrn			; clrscrn BIOS call


; draw checkerboard -----------------------------------------
	clr	8			; 0-> r8. (r8 used to flip bit 0/1)

	li	2			; shift (0|1)
	lr	5, a

	li	11			; (r4) number of iterations (ysize)
	lr	4,a			; a->r4

	li	$40			; color
	lr	1, a

nextln:

	lr	a,4			; load y0
	ai	23			; a+const->a  (y0)
	lr	3, a

	li	50			; related to xsize
	lr	7,a			; (r7) number of iterations (x)

; xor r8 with 1 (flip 1 <-> 0)
	li	1
	xs	8				; a xor r8 -> a
	lr	8,a

; r8 + 103 -> r2
	li	103			; related to x0 WAS:42
	as	8			; x = x+y (shift by 1 pixel) 
	lr	2,a			; (r2) coord (x)


; draw dotted line
nextpx:

	li	$80			; color ($00, $40, $80)
	lr	1,a

	pi plot			; r1 - color, r2 - x, r3 - y  (a,r6 also lost)

	ds	2			; r2-- (coord)
	ds	2			; r2-- (coord)

	ds	7			; r7-- (number of iterations)
	bnz nextpx		; until r7 = 0

	ds	4			; r4--
	bnz nextln		; until r2 = 0



; draw chars "CC2019" (GG1 used to make inversed CC because lack of "C" in BIOS)
; "1"
	li	20 + xc0	; x
	lr	1,a
	li	yc0			; y
	lr	2,a
	li	$c1
	lr	0,a			; combined color + char index -> r0
	pi	drawchar            

; "G"
	li	12 + xc0	; x
	lr	1,a
	li	$ca
	lr	0,a			; combined color + char index -> r0
	pi	drawchar            

; "G"
	li	17 + xc0	; x
	lr	1,a
	li	$ca
	lr	0,a			; combined color + char index -> r0
	pi	drawchar            

; "2"
	li	24 + xc0	; x
	lr	1,a
	li	$82
	lr	0,a		; combined color + char index -> r0
	pi	drawchar            
; "1"
	li	34 + xc0			; x
	lr	1,a
	li	$81
	lr	0,a		; combined color + char index -> r0
	pi	drawchar            
; "0"
	li	30 + xc0			; x
	lr	1,a
	li	$80
	lr	0,a		; combined color + char index -> r0
	pi	drawchar            
; "9"
	li	38 + xc0			; x
	lr	1,a
	li	$89
	lr	0,a		; combined color + char index -> r0
	pi	drawchar            


AGAIN:

	li	13	; (r0) number of iterations 
	lr	0,a	; a->r0

nextline:

	li	23	; y0
	as	0	;	r0+a->a
	lr	3,a

; set palette for line (y: r3)
;
; 00->125, 00->126: rgb, lightgreen back
; 00->125, ff->126: rgb, lightblue back
; ff->125, 00->126: rgb, transparent (gray) back
; ff->125, ff->126: www, black back


; restore color of lower line  (e.g. 5 with gray back)

	clr				; color (0 -> a)
	lr	1,a

	li	126			; x
	lr	2,a

	pi plot

	li	$ff			; color
	lr	1,a

	ds	2
	pi plot

	lr	a,3		; save r3
	lr	4,a

	ds	3

; change color of upper line  (e.g. 6 with black back)

	li	$ff			; color
	lr	1, a

	li	126			; x
	lr	2, a

	pi plot
	ds	2
	pi plot

;------

; blinking lines


	li	126			; x
	lr	2, a

	li	23			; y
	lr	3, a

	clr				; color
	lr	1, a


	lr	a,8			; color
	lr	1, a
	pi plot

	ds	2

	clr				; color
	lr	1, a
	pi plot

	lr	a,3
	ai 	12			; a+=12	
	lr	3,a

	lr	a,2
	inc
	lr	2,a

	lr	a,8			; color
	lr	1,a
	pi plot

	ds	2

	clr				; color
	lr	1,a
	pi plot

	lr	a,8
	xi	$ff			; change 00 with FF to blink
	lr	8,a



	lr	a,4		; restore r3
	lr	3,a


; setpal end



; delay moving line through the checkerboard

	li	40
	lr	1,a
delay2:          
	li	$ff		
	lr	2,a                
delay1:    
	ds	2                  
	bnz	delay1          
	ds	1
	bnz	delay2            



	ds	0			; r0--
	bnz nextline	; until r0 = 0

; restore top line


; restore color of lower line  (e.g. 5 with gray back)
	ds	3

	clr				; color (0->a)
	lr	1, a

	li	126			; x
	lr	2, a

	pi plot

	li	$ff			; color
	lr	1, a

	ds	2
	pi plot

	li	%11000000   ; 1kHz beep $40 (rather click)
	outs 5
	clr
	outs 5

	jmp	AGAIN

loop:	jmp	loop


; plot point
; r1 = color  $00 = green, $40 = %01000000 = red, $80 = %10000000 = blue, $C0 = %11000000 = background
; r2 = x (to screen) (4-105) (0-101)
; r3 = y (to screen) (4-61) (0-57)

plot:
	; set the color using r1
	lr		A, 1
	outs	1

	; set the column using r2
	lr		A, 2
	com
	outs	4

	; set the row using r3
	lr	A, 3
	com
	outs	5

	; transfer data to the screen memory
	li		$60
	outs	0
	li		$50
	outs	0

	; delay until it's fully updated
	lis	6
.plotDelay:	
	ai	$ff
	bnz	.plotDelay

	pop				; return from the subroutine


	org $fff        ; added only to set a useable rom-size in MESS
	.byte   $ff
