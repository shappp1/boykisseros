ch_help:  ; TODO please add a convert to uppercase function for the arg
  mov si, ax
  call split_args
  xchg si, ax
  mov di, str_generic
  call cmps
  je .generic
  mov di, str_file
  call cmps
  je .file
  mov di, str_writing
  call cmps
  je .writing
  mov di, str_debug
  call cmps
  je .debug
  .sections:
    mov si, str_help_sections
    call puts
    jmp command_loop
  .generic:
    mov si, str_help_generic
    call puts
    jmp command_loop
  .file:
    mov si, str_help_file
    call puts
    jmp command_loop
  .writing:
    mov si, str_help_writing
    call puts
    jmp command_loop
  .debug:
    mov si, str_help_debug
    call puts
    jmp command_loop

ch_clear:
  call clear
  jmp command_loop

ch_echo:
  mov si, ax
  call puts
  mov si, str_endl
  call puts
  jmp command_loop

ch_color:
  mov si, ax
  call strlen
  test cx, cx
  jz .inv
  cmp cx, 2
  ja .inv
  call hex_to_word
  jc .inv
  mov [color], cl
  jmp command_loop
  .inv:
    mov si, str_color
    call puts
    jmp command_loop

ch_boyfetch:
  mov si, str_boyfetch
  call puts
  jmp command_loop