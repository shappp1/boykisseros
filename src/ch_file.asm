ch_ls:
  mov si, ls_msg
  call puts
  push ds
  xor bx, bx
  mov ds, bx
  mov si, directory_buffer
  test byte [si + 11], 0x08
  jz .outer_loop
  .skip:
    add si, 0x20
  .outer_loop:
    cmp byte [si], 0x05
    je .skip
    cmp byte [si], 0xE5
    je .skip
    cmp byte [si], 0
    je .end
  .attrib_loop:
    mov ah, [si+0x0b]
    pop ds
    mov al, '['
    call putch
    test ah, 0x02
    jz .no_hidden_attrib
    mov al, 'H'
    call putch
    jmp .hidden_attrib
  .no_hidden_attrib:
    mov al, '-'
    call putch
  .hidden_attrib:
    test ah, 0x04
    jz .no_system_attrib
    mov al, 'S'
    call putch
    jmp .system_attrib
  .no_system_attrib:
    mov al, '-'
    call putch
  .system_attrib:
    test ah, 0x01
    jz .no_ro_attrib
    mov al, 'R'
    call putch
    jmp .ro_attrib
  .no_ro_attrib:
    mov al, '-'
    call putch
  .ro_attrib:
    test ah, 0x20
    jz .no_archive_attrib
    mov al, 'A'
    call putch
    jmp .archive_attrib
  .no_archive_attrib:
    mov al, '-'
    call putch
  .archive_attrib:
    mov al, ']'
    call putch
    mov al, ' '
    call putch
    push ds
    mov ds, bx
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
    test byte [si], 0x10
    jz .put_size
    pop ds
    push si
    mov si, dir_msg
    call puts
    jmp .next
  .put_size:
    mov ecx, [si + 0x11] ; size
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
  .end:
    pop ds
    jmp command_loop

ch_cd:
  push es
  mov si, ax
  cmp byte [si], 0
  je .fail
  .args_loop:
    cmp byte [si], ' '
    jne .args_good
    call split_args
    jmp .args_loop
  .args_good:
  push si
  call split_args
  pop si
  pop es

  .path_loop:
    push es
    call parse_path

    cmp byte es:[di], '/'
    je .read_root

    call find_file
    jc .fail

    test byte es:[di + 11], 0x10
    jz .fail

    mov ax, es:[di + 26]
    test ax, ax
    jz .read_root

    mov bx, directory_buffer
    call read_cluster_chain
    jmp .check_next

    .read_root:
      xor ax, ax
      mov es, ax
      mov ax, 19 ; FIX HARD CODED -> reserved + fat_count * sectors_per_fat
      mov bx, directory_buffer
      mov cl, 14 ; FIX HARD CODED (maybe)
      mov dl, [0x7c00 + 36]
      call read_disk
      jc .fail
    
    .check_next:
      pop es
      cmp byte [si], 0
      je command_loop
      jmp .path_loop

  .fail:
    pop es
    mov si, cd_msg
    call puts
    jmp command_loop

ch_type:
  push es
  mov si, ax
  cmp byte [si], 0
  je .fail
  .args_loop:
    cmp byte [si], ' '
    jne .args_good
    call split_args
    jmp .args_loop
  .args_good:
  push si
  call split_args
  pop si
  
  call parse_path

  call find_file
  jc .fail

  test byte es:[di + 11], 0x10
  jnz .fail

  mov ax, es:[di + 26]
  mov bx, file_buffer
  call read_cluster_chain

  pop es
  push ds
  xor ax, ax
  mov ds, ax
  mov si, file_buffer
  call puts
  pop ds
  mov si, endl_msg
  call puts
  jmp command_loop

  .fail:
    pop es
    mov si, cd_msg
    call puts
    jmp command_loop
