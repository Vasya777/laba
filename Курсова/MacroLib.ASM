macro clr reg
{
	xor reg,reg
}

macro push [arg]{ push arg}

macro pop [arg] {pop arg}

macro exit_app
{
	mov ax,4C00h
	int 21h
}

macro pause
{
	mov ah,08h
	int 21h
}

;-----------------------------------------------
;i&j numbers , NOT variables  ,rowc - reg bl , type - adress
;OUT: SI - адресс элемента
macro get_el i,j,type
{
	push ax,bx,cx,dx
	clr ax
	clr bh
	mov al,[type]
	;bl - rowc
	mul bl
	mov bx,i
	mul bl
	add ax,j
	add si,ax
	pop dx,cx,bx,ax
}