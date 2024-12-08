ch_sp:
  mov si, command_buffer
  .loop:
  mov cx, 0xFF
  call gets
  test cx, cx
  jz .loop
  jmp command_loop

ch_numtest:
  mov si, str_endl
  mov ecx, 134
  mov dx, 0x008f
  call fputint32
  call puts
  mov ecx, -3514
  call fputint32
  call puts
  mov dh, ','
  call fputint32
  call puts
  mov dl, 0x0f
  call fputint32
  call puts
  mov ecx, 1234
  xor dl, dl
  call fputint32
  call puts
  jmp command_loop