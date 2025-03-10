cmps: ; bool cmps(char *string1, char *string2) ; compares two strings and returns if they are equal
  push bp
  mov bp, sp
  push es
  push di
  push ds
  push si

  mov di, [bp+4]
  mov es, [bp+6]
  mov si, [bp+8]
  mov ds, [bp+10]

  .loop:
    mov al, [si]
    mov ah, es:[di]
    cmp al, ah
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
  .not_equal:
    xor ax, ax
    jmp .done
  .equal:
    mov ax, 1
  .done:
    pop si
    pop ds
    pop di
    pop es
    pop bp
    ret 8

to_upper: ; void to_upper(char *string) ; converts a string to uppercase
  push bp
  mov bp, sp
  push ds
  push si
  push ax

  mov si, [bp+4]
  mov ds, [bp+6]

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
    mov [si - 1], al
    jmp .loop
    
  .end:
    pop ax
    pop si
    pop ds
    pop bp
    ret 4

strlen: ; uint16 strlen(char *string) ; returns the length of a string
  push bp
  mov bp, sp
  push ds
  push si
  push cx

  mov si, [bp+4]
  mov ds, [bp+6]

  mov cx, -1
  .loop:
    lodsb
    inc cx
    test al, al
    jnz .loop
    
  mov ax, cx

  pop cx
  pop si
  pop ds
  ret 4

; hex_to_word: ; takes a pointer to a hex string and returns its value | params: ( string: ds:si ) | returns: ( value: cx, invalid: CF )
;   push si
;   push ax
;   call strlen
;   test cx, cx
;   jz .inv
;   cmp cx, 4
;   ja .inv
;   mov ax, cx
;   xor cx, cx
;   cmp ax, 1
;   je .one
;   cmp ax, 2
;   je .two
;   cmp ax, 3
;   je .three
;   .four:
;     mov al, [si]
;     call .char2nibble
;     cmp al, -1
;     je .inv
;     shl ax, 12
;     or cx, ax
;     inc si
;   .three:
;     mov al, [si]
;     call .char2nibble
;     cmp al, -1
;     je .inv
;     shl ax, 8
;     or cx, ax
;     inc si
;   .two:
;     mov al, [si]
;     call .char2nibble
;     cmp al, -1
;     je .inv
;     shl ax, 4
;     or cx, ax
;     inc si
;   .one:
;     mov al, [si]
;     call .char2nibble
;     cmp al, -1
;     je .inv
;     or cx, ax
;   clc
;   jmp .end
;   .inv:
;     xor cx, cx
;     stc
;   .end:
;     pop ax
;     pop si
;     ret
;   .char2nibble: ; SUBFUNC takes character and returns hex value | params: ( char: al ) | returns: ( nibble: al ) | invalid character: -1 -> al
;     cmp al, '9'
;     jle .s.le9
;     cmp al, 'F'
;     jle .s.leF
;     cmp al, 'f'
;     jle .s.lef
;     .s.inv:
;       mov al, -1
;       ret
;     .s.le9:
;       cmp al, '0'
;       jge .s.ge0
;       jmp .s.inv
;     .s.leF:
;       cmp al, 'A'
;       jge .s.geA
;       jmp .s.inv
;     .s.lef:
;       cmp al, 'a'
;       jge .s.gea
;       jmp .s.inv
;     .s.ge0:
;       sub al, '0'
;       ret
;     .s.geA:
;       sub al, 0x37
;       ret
;     .s.gea:
;       sub al, 0x57
;       ret

; returns a pointer to '\0' if end of string is found
split_args: ; char *split_args(char *string) ; looks for the first space in string, changes it to 0, and returns pointer to first non-space character after space(s)
  push bp
  mov bp, sp
  push ds
  push si

  mov si, [bp+4]
  mov ds, [bp+6]

  .loop:
    lodsb
    cmp al, ' '
    je .space
    test al, al
    jz .end
    jmp .loop

  .space:
    mov byte [si-1], 0
    lodsb
    cmp al, ' '
    je .space

  .end:
    mov ax, si
    mov dx, ds
    dec ax
    pop si
    pop ds
    pop bp
    ret 4