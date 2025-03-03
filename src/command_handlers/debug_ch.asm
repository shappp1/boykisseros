ch_sp:
  .loop:
    push 0xFF
    push ds
    push command_buffer
    call gets
    test ax, ax
    jz .loop
  jmp command_loop

ch_numtest:
  mov si, str_endl

  mov ecx, 134
  mov dx, 0x008f
  call fputint32
  push ds
  push si
  call puts

  mov ecx, -3514
  call fputint32
  push ds
  push si
  call puts

  mov dh, ','
  call fputint32
  push ds
  push si
  call puts

  mov dl, 0x0f
  call fputint32
  push ds
  push si
  call puts
  
  mov ecx, 1234
  xor dl, dl
  call fputint32
  push ds
  push si
  call puts
  jmp command_loop