cmps: ; compares two strings | params: ( string1: ds:si, string2: es:di ) | returns: ( equal: CF )
  push di
  push si
  push ax

  .loop:
    mov al, ds:[si]
    mov ah, es:[di]
    cmp al, ah
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
  .not_equal:
    clc
    jmp .done
  .equal:
    stc
  .done:
    pop ax
    pop si
    pop di
    ret

to_upper: ; converts a string to uppercase | params: ( string: ds:si ) | returns: void
  push si
  push ax

  .loop:
    lodsb
    test al, al
    ; if al = 0 then done
    jz .end
    ; if al not between 0x61 and 0x7A then it's not a lowercase character
    cmp al, 0x61
    jl .loop
    cmp al, 0x7A
    jg .loop
    ; subtract 0x20 to convert lowercase character to uppercase
    sub al, 0x20
    mov ds:[si - 1], al
    jmp .loop
    
  .end:
    pop ax
    pop si
    ret

strlen: ; gets the length of a string | params: ( string: ds:si ) | returns ( length: cx )
  push si
  mov cx, -1
  .loop:
    lodsb
    inc cx
    test al, al
    jnz .loop
  pop si
  ret

hex_to_word: ; takes a pointer to a hex string and returns its value | params: ( string: ds:si ) | returns: ( value: cx, invalid: CF )
  push si
  push ax
  call strlen
  test cx, cx
  jz .inv
  cmp cx, 4
  ja .inv
  mov ax, cx
  xor cx, cx
  cmp ax, 1
  je .one
  cmp ax, 2
  je .two
  cmp ax, 3
  je .three
  .four:
    mov al, [si]
    call .char2nibble
    cmp al, -1
    je .inv
    shl ax, 12
    or cx, ax
    inc si
  .three:
    mov al, [si]
    call .char2nibble
    cmp al, -1
    je .inv
    shl ax, 8
    or cx, ax
    inc si
  .two:
    mov al, [si]
    call .char2nibble
    cmp al, -1
    je .inv
    shl ax, 4
    or cx, ax
    inc si
  .one:
    mov al, [si]
    call .char2nibble
    cmp al, -1
    je .inv
    or cx, ax
  clc
  jmp .end
  .inv:
    xor cx, cx
    stc
  .end:
    pop ax
    pop si
    ret
  .char2nibble: ; SUBFUNC takes character and returns hex value | params: ( char: al ) | returns: ( nibble: al ) | invalid character: -1 -> al
    cmp al, '9'
    jle .s.le9
    cmp al, 'F'
    jle .s.leF
    cmp al, 'f'
    jle .s.lef
    .s.inv:
      mov al, -1
      ret
    .s.le9:
      cmp al, '0'
      jge .s.ge0
      jmp .s.inv
    .s.leF:
      cmp al, 'A'
      jge .s.geA
      jmp .s.inv
    .s.lef:
      cmp al, 'a'
      jge .s.gea
      jmp .s.inv
    .s.ge0:
      sub al, '0'
      ret
    .s.geA:
      sub al, 0x37
      ret
    .s.gea:
      sub al, 0x57
      ret

split_args: ; looks for the first space in a string, changes it to 0, and returns address of character after space | params: ( command: ds:si ) | returns: ( arg: ds:si )
  push ax

  .loop:
    lodsb
    cmp al, ' '
    je .space
    test al, al
    jz .zero
    jmp .loop
  .zero:
    dec si
    jmp .end
  .space:
    mov byte ds:[si-1], 0
  .end:
    pop ax
    ret