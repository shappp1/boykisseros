ch_ls:
  mov si, ls_msg
  call puts
  push ds
  xor bx, bx
  mov ds, bx
  mov ah, 0x0e
  mov si, directory_buffer
  add si, 0x20
  .outer_loop:
    cmp byte ds:[si], 0x05
    je .skip
    cmp byte ds:[si], 0xE5
    je .skip
    cmp byte ds:[si], 0
    je .end
    mov ch, 1
    mov cl, 8
  .name_loop:
    lodsb
    int 0x10
    dec cl
    cmp cl, 0
    jg .name_loop
    test ch, ch
    jz .is_dir
    mov al, ' '
    int 0x10
    mov cl, 3
    xor ch, ch
    jmp .name_loop
  .is_dir:
    test byte ds:[si], 0x10
    jz .put_size
    pop ds
    push si
    mov si, dir_msg
    call puts
    pop si
    push ds
    jmp .next
  .put_size:
    mov ecx, ds:[si + 0x11] ; size
    mov al, 10
    pop ds
    call rputint32
    push ds
  .next:
    xor cx, cx
    mov ds, cx
    mov al, 10
    int 0x10
    mov al, 13
    int 0x10
    add si, 0x15
    jmp .outer_loop
  .skip:
    add si, 0x20
    jmp .outer_loop
  .end:
    pop ds
    jmp command_loop

;; LOCAL FUNCTIONS

rputint32: ; right-aligned put int32 | params: ( int: ecx, max: al ) | returns: void
  push di
  push si
  push edx
  push ecx
  push eax

  push cx
  mov di, .buffer_start
  mov al, ' '
  mov cx, 10
  rep stosb
  pop cx

  mov di, .buffer_end
  std
  test ecx, ecx
  jz .zero
  .loop:
    mov eax, ecx
    mov ecx, 10
    xor edx, edx
    div ecx
    mov ecx, eax
    mov eax, edx
    add al, '0'
    stosb
    test ecx, ecx
    jz .end
    jmp .loop
  .zero:
    mov al, '0'
    stosb
  .end:
    cld
    pop eax
    push eax
    xor ah, ah
    mov si, .buffer_start
    add si, 10
    sub si, ax
    call puts
    pop eax
    pop ecx
    pop edx
    pop si
    pop di
    ret
  .buffer_start: times 9 db 0
  .buffer_end: times 2 db 0