; I am temporarily(?) removing the color command
; set_color: ; void color(uint8 color) ; sets color attribute for entire screen
;   push bp
;   mov bp, sp
;   push ds
;   push si
;   push ax

;   mov al, [bp + 4] ; al = color
;   mov si, 0xb800
;   mov ds, si
;   xor si, si ; ds:si = start address of screen
;   .loop:
;     inc si
;     mov byte [si], al
;     inc si
;     cmp si, 0xFA0
;     jl .loop

;   pop ax
;   pop si
;   pop ds
;   pop bp
;   ret 2

clear: ; void clear(void) ; clears the screen
  push dx
  push cx
  push bx
  push ax

  ; clear screen with set color
  mov ax, 0x0600
  mov bh, 0x07
  xor cx, cx
  mov dx, 0x184f
  int 0x10

  ; set cursor position to 0, 0 on page 0
  mov ah, 0x02
  xor bh, bh
  xor dx, dx
  int 0x10

  pop ax
  pop bx
  pop cx
  pop dx
  ret