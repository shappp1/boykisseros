putch: ; void putch(char character) ; prints a character to the screen  
  push bp
  mov bp, sp
  push bx
  push ax

  mov ah, 0x0e
  mov al, [bp+4]
  xor bx, bx
  int 0x10

  pop ax
  pop bx
  pop bp
  ret 2

puts: ; void puts(char *string) ; prints a string to the screen
  push bp
  mov bp, sp
  push si
  push bx
  push ax

  mov si, [bp+4]
  mov ds, [bp+6]
  xor bh, bh
  mov ah, 0x0e
  .loop:
    lodsb
    test al, al
    jz .end
    int 0x10
    jmp .loop

  .end:
    pop ax
    pop bx
    pop si
    pop bp
    ret 4

gets: ; bool gets(char *buffer, uint16 max_count) ; gets a string from the user and returns true if terminated (^C)
  push bp
  mov bp, sp
  push es
  push di
  push dx
  push cx

  mov di, [bp+4]
  mov es, [bp+6]
  mov cx, [bp+8]

  xor dx, dx
  .loop:
    xor ah, ah
    int 0x16
    cmp al, 8
    je .backspace
    cmp al, 13
    je .end
    cmp al, 10
    je .end
    cmp al, 3
    je .break

    cmp dx, cx
    je .loop
    inc dx

    stosb
    push ax
    call putch
    jmp .loop
  .backspace:
    test dx, dx
    jz .loop
    push 8
    call putch
    push 0
    call putch
    push 8
    call putch
    dec di
    dec dx
    jmp .loop
  .break:
    push '^'
    call putch
    push 'C'
    call putch
    mov ax, 1
    jmp .terminated
  .end:
    xor ax, ax
  .terminated:
    mov byte es:[di], 0
    push ds
    push str_endl
    call puts
    pop cx
    pop dx
    pop di
    pop es
    pop bp
    ret 6

; NOTE: seperator and right_align are optional, load with 0 to disable
; WARNING: right_align must have enough space to fit entire number, including seperators and signs, otherwise there will be undefined behaviour

fputint32: ; void fputint32(int32 n, char seperator, uint8 right_align, bool signed) ; prints an integer to the screen
  push bp
  mov bp, sp
  push edx
  push ecx
  push bx
  push eax

  mov ecx, [bp+4]
  mov dh, [bp+8]
  mov dl, [bp+10]
  and dl, 0x7F
  cmp byte [bp+12], 0
  je ._unsigned
  or dl, 0x80
._unsigned:

  test dl, 0x80
  jz .unsigned
  and dl, 0x7F
  cmp ecx, 0
  jge .unsigned
  neg ecx
  or dl, 0x80
  .unsigned:
  test dl, 0x7F
  jz .no_align
  cmp ecx, 0
  jge .not_large
  mov bl, 10
  jmp .align
  .not_large:
  mov bl, 1
  mov eax, 10
  .align_loop:
    cmp ecx, eax
    jl .align
    inc bl
    lea eax, [eax + eax * 4]
    add eax, eax
    jmp .align_loop
  .align:
    test dl, 0x80
    jz .no_neg_align
    dec dl
    .no_neg_align:
    test dh, dh
    jz .no_sep_align
    cmp bl, 9
    jg .sep_align_3
    cmp bl, 6
    jg .sep_align_2
    cmp bl, 3
    jg .sep_align_1
    jmp .no_sep_align
    .sep_align_3:
      dec dl
    .sep_align_2:
      dec dl
    .sep_align_1:
      dec dl
  .no_sep_align:
    sub dl, bl
    test dl, 0x7f
    jle .no_align
    .space_loop:
      push ' '
      call putch
      dec dl
      test dl, 0x7f                                            
      jg .space_loop
  .no_align:
  test ecx, ecx
  jz .zero
  test dl, 0x80
  jz .pos
  push '-'
  call putch
  .pos:
  xor bl, bl
  mov bh, dh
  .loop:
    mov eax, ecx
    mov ecx, 10
    xor edx, edx
    div ecx
    push dx
    inc bl
    mov ecx, eax
    test ecx, ecx
    jz .print
    jmp .loop
  .zero:
    push '0'
    call putch
    jmp .end
  .print:
    mov dh, bh
  .print_loop:
    pop ax
    add al, '0'
    push ax
    call putch
    dec bl
    test dh, dh
    jz .no_sep
    cmp bl, 9
    je .sep 
    cmp bl, 6
    je .sep
    cmp bl, 3
    je .sep
    jmp .no_sep
  .sep:
    mov al, dh
    push ax
    call putch
  .no_sep:
    test bl, bl
    jnz .print_loop
  .end:
    pop eax
    pop bx
    pop ecx
    pop edx
    pop bp
    ret 10