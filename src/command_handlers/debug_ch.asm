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
  push 1
  push 15
  push 0
  push ecx
  call fputint32
  push ds
  push si
  call puts

  push 1
  push 15
  push 0
  push dword -3514
  call fputint32
  push ds
  push si
  call puts

  push 1
  push 15
  push ','
  push dword -3514
  call fputint32
  push ds
  push si
  call puts

  push 0
  push 15
  push ','
  push dword -3514
  call fputint32
  push ds
  push si
  call puts
  
  push 0
  push 0
  push ','
  push dword 1234
  call fputint32
  push ds
  push si
  call puts
  jmp command_loop