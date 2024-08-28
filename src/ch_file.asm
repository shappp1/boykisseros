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
    mov dx, 10
    call fputint32
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