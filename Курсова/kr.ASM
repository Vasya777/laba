format MZ
entry Code_seg:start
include 'MacroLib.ASM'
stack 1000h


segment data_seg
;----------------I/O Data------------------
endline db 13,10,'$'
sign db ?
;------------------------------------------
number_buf rb 20
buf_size db 20
out_str rb 20
;------------------------------------------


rowc db ?
colc db ?
in_rowc_str db 'Enter row_count:$'
in_colc_str db 'Enter col_count:$'
in_numb_mes db 'Enter number # $'
Un_Ex_m db 'For this matrix unexist invert matrix, because determinant = 0$'
Answer db 'Invert matrix',0Dh,0Ah,'1/$'
offset db '      $'
space db ' $'
star db '*$'
dpoint db ':$'
type db 1
count db 0
enter_type db 0
Res db 'Res.txt',0
mes_error db 'Error$'
mes_error4 db 'Error:Incorrect record from file$'
mes_error3 db 'Error:File not open$'
mes_error2 db 'Error: matrix is not square!!!$'
mes_error5 db 'Error:Try again$'
Det_mes db 'Determinant:$'
enter_type_mes db 'Choose how input',13,10,'Console - 1',13,10,'File - 2',13,10,'Your choice:$'
handle rw 1 ;дескриптор файла

;------------------------------------
file_name db 'matrix.txt$'
buffer rb 2048 ;файловый буффер
buf_count db 0
Determinant dd ?
invert_matr rw 1024
matrix rb 1024
;------------------------------------

;------------------------------------

segment Code_seg
start:
	mov ax,data_seg
	mov ds,ax

	@@:
	mov dx,enter_type_mes
	call print_str
	mov al,18
	mov si,number_buf
	call in_int32x_numb
	jc FAIL
	mov [enter_type],al
	cmp al,1
	je m3
	cmp al,2
	je .m2
	mov dx,mes_error3
	call print_str
	call endl
	jmp @B

.m2:
;---------------------Открытие файла
	mov ah,3Dh
	clr al
	mov dx,file_name
	clr cx
	int 21h
;----------------проверка на ошибку открытия
	jnc @F
	    mov dx,mes_error3
	    call print_str
	    call endl
	    jmp exit
;------------------------------Ввод в буфер
	@@:
	mov [handle],ax
	mov bx,ax
	mov ah,3Fh
	mov dx,buffer
	mov cx,2048
	int 21h

;-----------проверка правильности записи
	jnc @F
	    mov dx,mes_error4
	    call print_str
	    call endl
	    jmp exit
	@@:
;-----------запись символа конца строки
	mov bx,buffer
	add bx,ax
	mov byte[bx],'$'

;--------------------------------------------------
close_file:
	mov ah,3Eh
	mov bx,[handle]
	int 21h
	jnc @F
	    mov dx,mes_error
	    call print_str
	    call endl
	    jmp exit
	@@:
;--------------------------------------
;Вывод ,входной из файла, матрицы или же вывод содержимого(80 знаков) файла
	mov ah,9
	mov dx,file_name
	int 21h

	call endl

	mov ah,9
	mov dx,buffer
	int 21h

	call endl
	call endl
;----Преобразование файлового буффра в матрицу---------------
;IN:
;OUT:
create_matrix:
	mov di,matrix
	mov si,buffer
	call define_number
	clr dx
	mov dl,ah
	call convert_int
	jnc @F
	    mov dx,mes_error
	    call print_str
	    call endl
	    jmp exit
	@@:
	mov [rowc],al

	add si,dx
	add si,2
	call define_number
	clr dx
	mov dl,ah
	call convert_int
	jnc @F
	    mov dx,mes_error
	    call print_str
	    call endl
	    jmp exit
	@@:
	mov [colc],al
	cmp al,[rowc]
	je @F
	    mov dx,mes_error2
	    call print_str
	    call endl
	    jmp exit
	@@:
	add si,dx
	add si,2
	mul [rowc]
	clr cx
	mov cl,al

	.lp1:
		call define_number
		cmp ah,0
		jne @F
			mov dx,mes_error
			call print_str
			call endl
			jmp exit
		@@:
		push ax
		call convert_int
		mov [di],al
		inc di
		pop ax
		clr al
		xchg ah,al
		add si,ax
		inc si
		mov al,[si]
		cmp al,0Ah
		jne .lp
		inc si
		.lp:
		loop .lp1
	jmp Invert_M
;------------------ввод размерности матрицы--------------
m3:
	mov dx,in_rowc_str
	call print_str
	mov al,18
	mov si,number_buf
	call in_int32x_numb
	mov [rowc],al
	call endl
	mov dx,in_colc_str
	call print_str
	mov al,18
	mov si,number_buf
	call in_int32x_numb
	mov [colc],al
	cmp al,[rowc]
	je @F
	    mov dx,mes_error2
	    call print_str
	    call endl
	    jmp exit
	@@:
	call endl
;--------------------------------------------------------

;------------------------------Ввод матрицы из клавиатуры
out_m:
	mov di,matrix
	clr cx
	clr bx
	mov cl,[rowc]
	loop1:
		inc bl
		xor bh,bh
		push cx
		mov cl,[rowc]
		loop2:
			inc bh
			mov dx,in_numb_mes
			call print_str
			mov al,bl
			mov si,out_str
			call convert_32x_int_numb
			mov dx,si
			call print_str
			mov dx,space
			call print_str
			mov al,bh
			mov si,out_str
			call convert_32x_int_numb
			mov dx,si
			call print_str
			mov dx,dpoint
			call print_str
			mov si,number_buf
			mov al,[buf_size]
			sub al,2
			call in_int32x_numb
			jnc @F
			   mov dx,mes_error5
			   call print_str
			   call endl
			   jmp loop2
			@@:
			mov [di],al
			inc di
			call endl
			loop loop2
		pop cx
		loop loop1


;----------------------------------------
Invert_M:
	mov ah,09h
	mov dx,Det_mes
	int 21h
	mov si,matrix
	mov al,[rowc]
	clr edx
	call Det_NxN
	push edx
	cmp edx,0
	jne @F
	    mov ah,09h
	    mov dx,Un_Ex_m
	    int 21h
	    call endl
	    jmp exit
	@@:
	pop edx
	mov eax,edx
	mov [Determinant],eax
	mov si,out_str
	call convert_32x_int_numb
	mov ah,09h
	mov dx,out_str
	int 21h

	mov si,matrix
	mov di,invert_matr
	mov al,[rowc]
	push ax
	clr ah
	clr cx
	mul al
	mov cx,ax ;
	pop ax
	clr ebx
	@@:
		push ax,bx,cx,si,di
		call Minor_matr
		mov si,di
		mov al,ah
		clr edx
		cmp al,1
		jne .m5
			mov dl,[si]
			jmp .m6
		.m5:
		call Det_NxN   ;поиск минора
		.m6:
		pop di,si,cx,bx,ax

		push ax,cx    ;------
		clr ax
		add al,bl
		add al,bh
		mov cx,0002h
		div cl
		cmp ah,0      ;поиск алгебраического дополнения
		je .m2
		    neg edx
		.m2:
		pop cx,ax      ;-----

		push ax,bx,di ;--------
		clr ah
		shl bh,2
		mul bh
		add di,ax
		clr bh	      ;транспонирование матрицы
		shl bx,2
		add di,bx
		mov [di],edx
		pop di,bx,ax  ;--------

		inc bh
		cmp bh,al
		jne .m1
		    inc bl
		    clr bh
		.m1:
	loop @B
	;на выходе обратная матрица , НЕ разделенная на определитель исходной


	mov ah,3Ch
	clr cx
	mov dx,Res
	int 21h
	jnc @F
	    mov dx,mes_error
	    call print_str
	    call endl
	    jmp exit
	@@:
	mov [handle],ax

	push ax,bx,cx,dx
	mov dx,Answer
	mov cl,18
	call writeF
	pop dx,cx,bx,ax

	call endl
	mov ah,09h
	mov dx,Answer
	int 21h

;-----------------------------

;----------------------------



	mov eax,[Determinant]
	mov si,out_str
	call convert_32x_int_numb


	mov dx,out_str
	mov cl,[count]
	push ax,bx,cx,dx
	call writeF
	pop dx,cx,bx,ax

	push ax,bx,cx,dx
	mov dx,star
	mov cl,2
	call writeF
	pop dx,cx,bx,ax

	push ax,bx,cx,dx
	mov dx,space
	mov cl,2
	call writeF
	pop dx,cx,bx,ax




	mov ah,09h
	mov dx,out_str
	int 21h
	mov ah,02h
	mov dx,'*'
	int 21h

	mov ah,02h
	mov dx,' '
	int 21h

	clr ax
	mov al,[rowc]
	mul al
	mov cx,ax
	clr bx
	mov di,invert_matr
	.lp2:
		mov eax,[di]
		mov si,out_str
		call convert_32x_int_numb

		push ax,bx,cx,dx
		mov dx,out_str
		mov cl,[count]
		call writeF
		pop dx,cx,bx,ax

		mov ah,09h
		mov dx,out_str
		int 21h
		mov al,[rowc]
		dec al
		cmp bh,al
		jne @F

		    push ax,bx,cx,dx
		    mov dx,endline
		    mov cl,3
		    call writeF
		    pop dx,cx,bx,ax

		    call endl
		    mov ah,09h
		    mov dx,offset
		    int 21h

		    push ax,bx,cx,dx
		    mov dx,offset
		    mov cl,7
		    call writeF
		    pop dx,cx,bx,ax

		@@:
		mov ah,02h
		mov dx,' '
		int 21h

		push ax,bx,cx,dx
		mov dx,space
		mov cl,2
		call writeF
		pop dx,cx,bx,ax

		add di,4
		inc bh
		cmp bh,[rowc]
		jne @F
		    clr bh
		    inc bl
		@@:

	loop .lp2
	call endl
	jmp exit

FAIL:
	mov dx,mes_error
	call print_str

exit:
	pause
	exit_app
;---------------Реализацыя кода кода поиска обратной матрицы--
;IN:
;SI - адресс матрицы размерности 2х2
;OUT:
;AX - определитель матрицы 2х2
Det_2x2:
	push bx,si
	mov bl,2
	clr ax

	push si
	get_el 0,0,type
	mov al,[si]    ;al = a1
	pop si

	push si
	get_el 1,1,type
	mov bh,[si]   ;bh = a4
	pop si

	imul bh 	;ax = a1*a4
	push ax

	push si
	get_el 0,1,type
	mov al,[si]    ;al = a2
	pop si

	push si
	get_el 1,0,type
	mov bh,[si]   ;bh = a3
	pop si

	imul bh        ;ax = a2*a3

	neg ax	      ;ax = -ax
	xchg ax,bx    ;bx xchange ax
	pop ax	      ;ax = a1*a4
	add ax,bx     ;ax = a1*a4 - a2*a3

	pop si,bx
	ret
;---------------------------------
;IN:
;SI - адресс матрицы
;AL - размерность матрицы
;EDX = 00000000h
;OUT:
;EDX - детерминант матрицы
Det_NxN:
	push ax,bx,cx,di   ;1
	cmp al,2
	jne .lp9
	    call Det_2x2
	    cmp ah,0
	    jne @F
		cbw
	    @@:
	    cwde
	    mov edx,eax
	    pop di,cx,bx,ax  ;1
	    ret
	clr cx
	.lp9:
	push ax,cx,edx,si ;2  ;сохранение размерности и адресса текущей матрицы , dx детерминат
	clr bl
	mov bh,cl
	call Minor_matr ;DI - адресс минорного определителя, AH - размерность определителя

	mov si,di
	mov al,ah
	clr edx
	call Det_NxN
	mov ebx,edx




	pop si,edx,cx,ax ;2 ;восстановление размерности и адресса текущей матрицы , dx детерминат

	;умножение определителя на минорный элемент
	push si,ax,edx	 ;3
	add si,cx
	clr ax
	mov al,[si]
	cmp ah,0
	jne @F
	    cbw
	    cwde
	@@:
	xchg eax,ebx
	imul ebx
	xchg eax,ebx
	pop edx,ax,si  ;3
	;------------------------------------------
	push ax,cx
	mov ax,cx
	mov cx,0002h
	div cl
	cmp ah,0
	je .m2
	   neg ebx
	.m2:
	pop cx,ax
	add edx,ebx

	inc cl
	cmp cl,al
	jne .lp9

	pop di,cx,bx,ax      ;1
	ret



;по адрессу matrix записывает определитель матрицы находящейся в стэке по минорному элементу
;IN:
;AL - размерность матрицы
;Bl - индекс минорного элемента по строке
;BH - индекс минорного элемента по столбцу
;SI - адресс матрицы , не сохраняется
;OUT:
;DI - адресс минорного определителя
;AH - размерность определителя
Minor_matr:
	push dx
	clr ah
	clr cx
	clr dx ;DH - столбец, DL - строка
	push ax
	mul al
	mov di,si
	add di,ax   ; DI - равно адрессу конца матрицы(адресс с которого будет новая матрица)
	mov cx,ax   ;CX - число элементов матрицы из которой будет создана минорная
	pop ax	 ;восстанавливаем размерность входной матрицы
	push di ;сохраняем адресс минорной матрицы
	.lp:
		clr ah
		cmp cx,0
		je .lp1
		cmp bl,dl
		jne @F	 ;сравнение по строчному индексу
		    add si,ax
		    sub cx,ax
		    inc dl
		    jmp .lp
		@@:
		cmp bh,dh
		jne @F	;сравнение по столбцовому индексу
		    inc si
		    dec cx
		    inc dh
		    cmp dh,al
		    jne .m1
			inc dl
			clr dh
		    .m1:
		    jmp .lp
		@@:
		mov ah,[si]
		mov [di],ah


		;цыкл
		inc dh
		cmp dh,al
		jne @F
			inc dl
			clr dh
		@@:
		inc si
		inc di
		dec cx
		cmp cx,0
		jne .lp
	.lp1:

	pop di
	mov ah,al
	dec ah ; размерность определителя будет меньше на 1 за размерность входной матрицы
	pop dx
	ret




;---------------------------Робочий код-----------------------
;IN:
;SI - первый символ числа(или предположительно числа)
;OUT:
;AH - количество символов числа
define_number:
	clr ax
	push si
	@@:
	mov al,[si]
	cmp al,'-'
	jne .lp
	    inc ah
	    inc si
	    jmp @B
	.lp:
	cmp al,'0'
	jl @F
	cmp al,'9'
	jg @F
	inc ah
	inc si
	jmp @B
	@@:
	pop si
	ret


;----------------------------------------------------
;DX - адресс того что нужно записать
;CL - колчество байт которые нужно записать
writeF:
    mov bx,[handle]
    mov ah,40h
    clr ch
    dec cl
    int 21h
    ret


;------------------I/O--------------------------------------------------------
;функция ввода строки с консоли
;IN:
;SI - адресс буфера для ввода строки
;AL - максимальное количество символов для ввода в буфер
;OUT:
;SI -  адресс(не изменяется) буфера с записаной строкой
input_str:
	push dx
	mov [si],al
	xor al,al
	mov [si+1],al
	mov ah,0Ah
	mov dx,si
	int 21h
	pop dx
	ret

;IN:
;DX - адресс строки для вывода
print_str:
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret

;переводит курсор на новою строку
;требуется глобальная переменная endline db 10,13,'$' ,  регистры не изменяються
endl:
	push dx
	mov dx,endline
	call print_str
	pop dx
	ret

;IN
;SI-адресс начала СТРОКИ числа
;AH-количество цифр
;OUT
;EAX-целое 32x число
;CF - 0 все ОК, 1 - ошыбка
convert_int:
	push cx
	push ebx
	push dx
	push si
	mov [sign],0
	mov al,[si]
	cmp al,'-'
	jne @F
	    mov [sign],1h
	    inc si
	    dec ah
	@@:
	xor cx,cx
	mov cl,ah
	xor eax,eax
	xor bx,bx
	lp.1:
		mov edx,0000000Ah
		mul edx
		mov bl,[si]
		cmp bl,'0'
		jnl @F
			CLC
			STC
			jmp .m1
		@@:
		cmp bl,'9'
		jng @F
			CLC
			STC
			jmp .m1
		@@:
		sub bl,'0'
		add eax,ebx
		inc si
		loop lp.1

	mov bl,[sign]
	cmp bl,1
	jne @F
	    neg eax
	@@:
	CLC
	.m1:
	pop si
	pop dx
	pop ebx
	pop cx
	ret

;IN:
;SI - адресс буфера
;AL - размер буфера(без учёта первых двух байт)
;OUT:
;EAX - 32х целое число
;CF - 0 все ОК, 1 - ошыбка
in_int32x_numb:
	push bx
	call input_str
	mov ah,[si+1]
	add si,2
	call endl   ; перенос курсора на следующую строку (можно закоментировать при необходимости)

	call convert_int

	pop bx
	ret
;-------------------------------------------
;-------------------------------------------
;IN:
;SI - адресс строки в которую будет записано число
;EAX - 32х целое число
;OUT:
;SI - адресс строки с числом
;!!! приведение к 32х формату выполнять при входе в процедуру нет необходимости
convert_32x_int_numb:
	mov [count],0
	cmp ah,0
	jne @F
		cbw
	@@:
	push eax
	shr eax,16
	cmp ax,0
	jne @F
	    pop eax
	    cwde
	    jmp .m1
	@@:
	pop eax
	.m1:
	push cx
	push ebx
	push si
	push dx
	xor cx,cx
	mov ebx,0000000Ah
	cmp eax,0
	jnl c3
	    mov dl,'-'
	    mov [si],dl
	    inc si
	    neg eax
	    add [count],1
	    jmp c3

	je c3
	   mov dl,'0'
	   mov [si],dl
	   add [count],1
	   jmp c4
	c3:
		xor edx,edx
		div ebx
		add dl,'0'
		push dx
		inc cl
		cmp eax,0
		jne c3
	add [count],cl
	lp.2:
		pop dx
		mov [si],dl
		inc si
		loop lp.2
	c4:
	mov dl,'$'
	mov [si],dl
	add [count],1
	pop dx
	pop si
	pop ebx
	pop cx
	ret