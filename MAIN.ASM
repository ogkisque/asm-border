.model tiny
.code
.286
org 100h

include cods.asm

locals @@

SizeXP 		equ 0
SizeYP		equ 1
ColorBackP	equ 2
NumStyleP	equ 3
HeaderP		equ 4
HeaderLenP	equ 6
TextP		equ 7
TextLenP	equ 9
StyleP		equ 10
StartPos	equ 1440d

Start:
		jmp Main

;----------------------------------------------------
; Writes a symbol line to video mem
; Entry:	ah - color attribute
;			cx - num of symbols
;			di - start position of text
;			si - offset to first symbol
; Assumes:	es - 0b800h
; Destr:	al, si, di, cx
   
PrintTextLine	proc
			
				@loop1:
					mov al, ds:[si]
					inc si
					stosw			; es:[di+=2] = ax
					loop @loop1

				ret
				endp
;----------------------------------------------------
; Writes a symbol to video mem
; Entry:	ah - color attribute
; Assumes:	es - 0b800h
; Destr:	di, bx, cx, si, al
   
PrintText	proc
			
			mov di, StartPos
			mov cl, ds:[HeaderLenP]
			xor ch, ch

			mov word ptr si, ds:[HeaderP]
			mov bl, ds:[SizeXP]
			mov bh, ds:[HeaderLenP]
			sub bl, bh 
			xor bh, bh
			add di, bx
			call PrintTextLine

			mov di, StartPos
			add di, 160d
			mov cl, ds:[TextLenP]
			xor ch, ch
			mov word ptr si, ds:[TextP]
			mov bl, ds:[SizeXP]
			mov bh, ds:[TextLenP]
			sub bl, bh 
			xor bh, bh
			add di, bx
			call PrintTextLine

			ret
			endp
;----------------------------------------------------
; Writes a line to video mem
; Entry:	ah - color attribute
;		si - start position of style
;		cl - length of border
;		di - start position of line
; Assumes:	es - 0b800h
; Destr: 	al, cl, di, si

PrintLine	proc

		lodsb		; al = ds:[si++]
		stosw		; es:[di] = ax; di += 2
		sub cl, 2
		lodsb
		rep stosw	; while (cx--) es:[di] = ax; di += 2
		lodsb
		stosw

		ret
		endp
;-------------------------------------------------
; Do delay
; Entry:
; Assumes:
; Destr:	ax, cx, dx

Delay		proc
		mov ax, 8600h
		mov cx, 3d
		mov dx, 17d
		int 15h
		ret
		endp
;-------------------------------------------------
; Writes border to video mem
; Entry:	
; Assumes:	es - 0b800h
; Destr:	ax, bx, cx, si, di

PrintBorder	proc
		mov si, ds:[StyleP]
		mov di, StartPos

		mov byte ptr cl, ds:[SizeXP]

		call PrintLine
		mov byte ptr bl, ds:[SizeYP]
		sub bl, 2
		@@loop:
			mov byte ptr cl, ds:[SizeXP]
			add di, 160d
			sub di, cx
			sub di, cx

			call PrintLine
			sub si, 3d
			dec bl
			cmp bl, 0
			jg @@loop

		add si, 3d
		mov byte ptr cl, ds:[SizeXP]
		add di, 160d
		sub di, cx
		sub di, cx
		call PrintLine

		ret
		endp	
;-------------------------------------------------
; Skip spaces
; Destr: si, cx, al

SkipSpaces		proc
				mov al, 020h
				@@loop1:
					cmp [si], al
					jne @@loop2

					inc si
					loop @@loop1
				@@loop2:
				ret
				endp
;-------------------------------------------------
; Parse number from command line
; Entry:	bx - address to put the
; Destr:	ax, si, cx 

ParseNum		proc

				mov al, [si]
				sub al, '0'
				shl al, 1d
				mov ah, al
				shl al, 1d 
				shl al, 1d 
				add al, ah		; al = [si] * 10

				inc si
				dec cx

				mov ah, [si]
				sub ah, '0'
				add al, ah
				xor ah, ah

				inc si
				dec cx

				mov [bx], al

				ret
				endp
;-------------------------------------------------
; Parse color from command line
; Entry:	bx - address to put the
; Destr:	ax, si, cx 

ParseCol		proc

				mov al, [si]
				cmp al, 'a'
				jge @@sym
					sub al, '0'
					jmp @@stop
				@@sym:
					sub al, 'a'
					add al, 10d
				@@stop:
				shl al, 1
				shl al, 1
				shl al, 1
				shl al, 1

				inc si
				dec cx

				mov ah, [si]
				cmp ah, 'a'
				jge @@sym1
					sub ah, '0'
					jmp @@stop1
				@@sym1:
					sub ah, 'a'
					add ah, 10d
				@@stop1:

				add al, ah
				xor ah, ah
				inc si
				dec cx

				mov [bx], al
				ret
				endp
;-------------------------------------------------
; Parse header from command line
; Entry:	
; Destr:	ax, bx, si, cx 

ParseHeader		proc

				xor ah, ah
				mov al, ':'
				@@loop1:
					cmp [si], al
					je @@loop2

					inc ah
					inc si
					loop @@loop1

				@@loop2:
					mov bx, HeaderLenP
					mov [bx], ah

				inc si
				dec cx

				ret
				endp
;-------------------------------------------------
; Parse style from command line
; Entry:	
; Destr:	ax, bx, si, cx, dx, di

ParseStyle		proc

				mov al, '*'
				cmp [si], al
				je @@new_style
					mov bx, NumStyleP
					call ParseNum

					mov di, offset StringArr
					mov byte ptr dl, ds:[NumStyleP]
					dec dl
					mov dh, dl
					shl dl, 3d
					add dl, dh		; dl = ([NumStyleP] - 1) * 9
					xor dh, dh
					add di, dx
					jmp @@break

				@@new_style:
					inc si
					mov di, si
					xor al, al
					@@loop1:
						inc si
						inc al
						dec cx
						cmp al, 9d
						je @@break
						jmp @@loop1

				@@break:
					mov bx, StyleP
					mov [bx], di

				ret
				endp
;-------------------------------------------------
; Parse command line
; Destr: ax, bx, si, cx

ParseCmd		proc
				xor cx, cx			; cx = 0
				mov cl, ds:[0080h]
				mov si, 81h

				call SkipSpaces
				mov bx, SizeXP
				call ParseNum

				call SkipSpaces
				mov bx, SizeYP
				call ParseNum

				call SkipSpaces
				mov bx, ColorBackP
				call ParseCol

				call SkipSpaces
				call ParseStyle

				call SkipSpaces
				mov bx, HeaderP
				mov [bx], si
				call ParseHeader

				call SkipSpaces
				mov bx, TextP
				mov [bx], si
				mov bx, TextLenP
				xor ch, ch
				mov [bx], cl

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
		call ParseCmd

		mov ax, 0b800h
		mov es, ax			; es = b800h

		mov byte ptr ah, ds:[ColorBackP]
		call PrintBorder

		call PrintText

		call ExitProg

StringArr	db 0dah, 0c4h, 0bfh, 0b3h, 020h, 0b3h, 0c0h, , 0d9h, 0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch, 03h, 03h, 03h, 03h, 020h, 03h, 03h, 03h, 03h

end    		Start