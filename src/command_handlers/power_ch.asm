ch_restart:
  mov word ss:[0x0472], 0
  jmp 0xf000:0xfff0

ch_electrocute:
  mov ax, 0x5300
  xor bx, bx
  int 0x15 ; INSTALLATION CHECK
  jc .error
  cmp ax, 0x101
  jl .error
  mov ax, 0x5304
  xor bx, bx
  int 0x15 ; DISCONNECT INTERFACE
  jc .dc_error
  .no_device:
    mov ax, 0x5301
    int 0x15 ; CONNECT REAL MODE INTERFACE
    jc .error
    mov al, 0x0e
    mov cx, 0x101
    int 0x15 ; SET APM VERSION TO 1.1
    jc .error
    mov ax, 0x5308
    mov bx, 1
    mov cx, bx
    int 0x15 ; ENABLE POWER MANAGEMENT ON ALL DEVICES
    jc .error
    mov al, 0x07
    mov cx, 3
    int 0x15 ; SET POWER TO OFF ON ALL DEVICES
  .dc_error:
    cmp ah, 3
    je .no_device
  .error:
    mov si, str_electrocute
    call puts
    jmp command_loop