.model tiny
.code
.286
org 100h

include cods.asm

Start:
		jmp Main

;----------------------------------------------------
; Writes a symbol to video mem
; Entry:	ah - color attribute
;   		al - symbol
;		bx - offset to video mem
; Assumes:	es - 0b800h
; Destr:
   
PrintSym	proc
		mov es:[bx], ax
		ret
		endp
;----------------------------------------------------
; Writes a lot of equal symbols to video mem
; Entry:	ah - color attribute
;		al - symbol
;		bx - offset to first symbol
;		si - number of characters
; Assumes:	es - 0b800h
; Destr: 	bx, cx

PrintLine	proc
		xor cx, cx		; cx = 0
		start_loop1:
			cmp cx, si	; if cx >= si
			jge stop_loop1	; break
			call PrintSym
			inc bx
			inc bx		; bx += 2
			inc cx		; cx++
			jmp start_loop1
		stop_loop1:
			ret
		endp
;-------------------------------------------------
; Writes border  to video mem
; Entry:	bx - position of border
; Assumes:	es - 0b800h
; Destr:	ax, bx, cx, si, di

PrintBorder	proc
		mov al, LUpBord
		mov si, 1d
		call PrintLine

		mov al, HorBord
		mov si, 30d
		call PrintLine

		mov al, RUpBord
		mov si, 1d
		call PrintLine
		
		xor di, di 		; di = 0
		start_loop2:
			add bx, 96d
			cmp di, 10
			jge stop_loop2

			mov al, VertBord
			mov si, 1d
			call PrintLine

			xor al, al	; al = 0 (empty)
			mov si, 30d
			call PrintLine

			mov al, VertBord
			mov si, 1d
			call PrintLine
			
			inc di
			jmp start_loop2
		
		stop_loop2:
		mov al, LLowBord
		mov si, 1d
		call PrintLine

		mov al, HorBord
		mov si, 30d
		call PrintLine

		mov al, RLowBord
		mov si, 1d
		call PrintLine
		
		ret
		endp
;-------------------------------------------------
; Writes shadow to border
; Entry: 	bx - position of border
; Assumes:	es - b800h
; Destr:	ax, bx, di, si

PrintShadow	proc

		add bx, 224d
		xor al, al		; al = 0
		mov ah, 01110000b	; ah = gray

		xor di, di		; di = 0
		mov si, 2d
		start_loop3:
			cmp di, 11
			jge stop_loop3

			call PrintLine
			add bx, 156d
			inc di
			jmp start_loop3

		stop_loop3:
		sub bx, 60d
		mov si, 32d
		call PrintLine
		
		ret
		endp		
;-------------------------------------------------
; Writes text to border
; Entry:	bx - position of border
; Assumes:	es - b800h
; Destr:	ax, bx, si, di

PrintText	proc

		add bx, 30d
		mov al, 'R'
		call PrintSym

		add bx, 2d
		mov al, 'T'
		call PrintSym

		add bx, 132d

		mov al, 3h
		mov ah, 01001010b
		mov si, 28d
		xor di, di		; di = 0

		loop_text:
			cmp di, 10
			jge loop_text_stop
			
			call PrintLine
			inc ah
			and ah, 01001111b
			inc di
			add bx, 104d
			jmp loop_text
		loop_text_stop:
		ret
		endp
;-------------------------------------------------
; Exit of programm
; Entry:
; Assumes:
; Destr:	ax

ExitProg	proc
		mov ax,  4c00h
		int 21h
		ret
		endp
;-------------------------------------------------
Main:
		mov ax, 0b800h
		mov es, ax

		mov ah, 01000001b
		mov bx, 1280d
		call PrintBorder
 
		mov bx, 1280d
		call PrintShadow
		
		mov ah, 01000001b
		mov bx, 1280d
		call PrintText

		call ExitProg

end    		Start