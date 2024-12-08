set_color: ; sets color attribute for entire screen | params: ( colour: bh ) | returns: void
  push ds
  push si
  push ax
  mov ax, 0xb800
  mov ds, ax
  xor si, si
  .loop:
    inc si
    mov ds:[si], bh
    inc si
    cmp si, 0xFA0
    jl .loop
  pop ax
  pop si
  pop ds
  ret

clear: ; clears the screen | params: void | returns: void
  push dx
  push cx
  push bx
  push ax
  mov ax, 0x0700
  mov bh, [color]
  xor cx, cx
  mov dx, 0x184f
  int 0x10
  mov ah, 0x02
  xor bh, bh
  xor dx, dx
  int 0x10
  pop ax
  pop bx
  pop cx
  pop dx
  ret