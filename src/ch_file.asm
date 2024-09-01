ch_ls:
  mov si, ls_msg
  call puts
  push ds
  xor bx, bx
  mov ds, bx
  mov si, directory_buffer + 0x20
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
    pop ds
    call putch
    push ds
    mov ds, bx
    dec cl
    cmp cl, 0
    jg .name_loop
    test ch, ch
    jz .is_dir
    mov al, ' '
    pop ds
    call putch
    push ds
    mov ds, bx
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
    jmp .next
  .put_size:
    mov ecx, ds:[si + 0x11] ; size
    mov dx, 10
    pop ds
    push si
    call fputint32
  .next:
    mov si, endl_msg
    call puts
    pop si
    push ds
    mov ds, bx
    add si, 0x15
    jmp .outer_loop
  .skip:
    add si, 0x20
    jmp .outer_loop
  .end:
    pop ds
    jmp command_loop

;; SPEC
;
; LIST ATTRIBUTES COMMAND
; FORMAT: [DHSRA]
; BLANK: -
;   EXAMPLE: [----A]
;
;; END SPEC