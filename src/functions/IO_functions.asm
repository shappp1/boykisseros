putch: ; prints a character to the screen | params: ( char: al ) | returns: void
  push bx
  push ax

  mov ah, 0x0e
  xor bx, bx
  int 0x10
  mov bh, [color]
  call set_color

  pop ax
  pop bx
  ret

puts: ; prints a string to the screen | params: ( string: ds:si ) | returns: void
  push si
  push bx
  push ax

  xor bh, bh
  mov ah, 0x0e
  .loop:
    lodsb
    test al, al
    jz .end
    int 0x10
    jmp .loop
  .end:
    mov bh, [color]
    call set_color

    pop ax
    pop bx
    pop si
    ret

;; NOTE: if terminated (^C), cx = -1, otherwise cx = 0
gets: ; gets a string from the user | params: ( buffer: es:di, max_count: cx ) | returns: ( terminated: cx )
  push di
  push si
  push dx
  push ax

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
    call putch
    jmp .loop
  .backspace:
    test dx, dx
    jz .loop
    mov al, 8
    call putch
    xor al, al
    call putch
    mov al, 8
    call putch
    dec di
    dec dx
    jmp .loop
  .break:
    mov al, '^'
    call putch
    mov al, 'C'
    call putch
    mov cx, -1
    jmp .terminated
  .end:
    xor cx, cx
  .terminated:
    mov byte es:[di], 0
    mov si, str_endl
    call puts
    pop ax
    pop dx
    pop si
    pop di
    ret

; NOTE: dh and dl are optional, load with 0 to disable
; WARNING: align_right must have enough space to fit entire number, including seperators and signs, otherwise there will be undefined behaviour
fputint32: ; prints an integer to the screen | params: ( int: ecx, seperator: dh, align_right: dl & 0x7F, is_signed: dl & 0x80 ) | returns: void
  push edx
  push ecx
  push bx
  push eax

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
    mov al, ' '
    .space_loop:
      call putch
      dec dl
      test dl, 0x7f                                            
      jg .space_loop
  .no_align:
  test ecx, ecx
  jz .zero
  test dl, 0x80
  jz .pos
  mov al, '-'
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
    mov al, '0'
    call putch
    jmp .end
  .print:
    mov dh, bh
  .print_loop:
    pop ax
    add al, '0'
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
    call putch
  .no_sep:
    test bl, bl
    jnz .print_loop
  .end:
    pop eax
    pop bx
    pop ecx
    pop edx
    ret