ch_help:  ; TODO please add a convert to uppercase function for the arg
  push ds
  push bx
  call split_args

  push ds
  push bx
  call to_upper

  push es
  push str_generic
  push ds
  push bx
  call cmps
  test al, al
  jnz .generic

  push es
  push str_file
  push ds
  push bx
  call cmps
  test al, al
  jnz .file

  push es
  push str_writing
  push ds
  push bx
  call cmps
  test al, al
  jnz .writing
  
  push es
  push str_debug
  push ds
  push bx
  call cmps
  test al, al
  jnz .debug
  
  ; else print help help
  push ds
  push str_help_sections
  call puts
  jmp command_loop

  .generic:
    push ds
    push str_help_generic
    call puts
    jmp command_loop
  .file:
    push ds
    push str_help_file
    call puts
    jmp command_loop
  .writing:
    push ds
    push str_help_writing
    call puts
    jmp command_loop
  .debug:
    push ds
    push str_help_debug
    call puts
    jmp command_loop

ch_clear:
  call clear
  jmp command_loop

ch_echo:
  push ds
  push bx
  call puts
  push ds
  push str_endl
  call puts
  jmp command_loop

ch_color:
  push ds
  push str_color
  call puts
  jmp command_loop
  ; mov si, ax
  ; call strlen
  ; test cx, cx
  ; jz .inv
  ; cmp cx, 2
  ; ja .inv
  ; call hex_to_word
  ; jc .inv
  ; mov [color], cl
  ; jmp command_loop
  ; .inv:
  ;   mov si, str_color
  ;   call puts
  ;   jmp command_loop

ch_boyfetch:
  push ds
  push str_boyfetch
  call puts
  jmp command_loop