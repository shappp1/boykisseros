%define default_color 0x07

%define endl 10, 13
%define end2l 10, 10, 13

%define FAT_buffer 0x7e00
%define directory_buffer 0x9000

[ORG 0x10000]
[BITS 16]
[map all build/main.map]

;; CODE

call clear
mov si, welcome_msg
call puts

command_loop:
  mov si, prompt
  call puts

  mov di, command_buffer
  mov cx, 0xFF
  call gets
  cmp cx, -1
  je command_loop
  cmp byte [di], 0
  je command_loop
  mov si, di
  call split_args
  mov ax, si

  mov si, help_cmd
  call cmps
  jc ch_help

  mov si, clear_cmd
  call cmps
  jc ch_clear

  mov si, echo_cmd
  call cmps
  jc ch_echo

  mov si, color_cmd
  call cmps
  jc ch_color

  mov si, boyfetch_cmd
  call cmps
  jc ch_boyfetch

  mov si, restart_cmd
  call cmps
  jc ch_restart

  mov si, electrocute_cmd
  call cmps
  jc ch_electrocute

  mov si, ls_cmd
  call cmps
  jc ch_ls

  mov si, cd_cmd
  call cmps
  jc ch_cd

  mov si, sp_cmd
  call cmps
  jc ch_sp

  mov si, numtest_cmd
  call cmps
  jc ch_numtest

  jmp ch_invalid

halt:
  cli
  hlt
  jmp halt

;; COMMAND HANDLERS

ch_help:
  mov si, help_msg
  call puts
  jmp command_loop

ch_clear:
  call clear
  jmp command_loop

ch_echo:
  mov si, ax
  call puts
  mov si, endl_msg
  call puts
  jmp command_loop

ch_color:
  mov si, ax
  call strlen
  test cx, cx
  jz .inv
  cmp cx, 2
  ja .inv
  call hex2word
  jc .inv
  mov [color], cl
  jmp command_loop
  .inv:
    mov si, color_msg
    call puts
    jmp command_loop

ch_boyfetch:
  mov si, boyfetch_msg
  call puts
  jmp command_loop

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
    mov si, electrocute_msg
    call puts
    jmp command_loop

%include "src/ch_file.asm"

ch_sp:
  mov si, command_buffer
  .loop:
  mov cx, 0xFF
  call gets
  test cx, cx
  jz .loop
  jmp command_loop

ch_numtest:
  mov si, endl_msg
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

ch_invalid:
  mov si, invalid_msg
  call puts
  jmp command_loop

;; FUNCTIONS

putch: ; prints a character to the screen | params: ( char: al ) | returns: void
  push bx
  push ax
  mov ah, 0x0e
  xor bx, bx
  int 0x10
  mov bh, [color]
  call setcolor
  pop ax
  pop bx
  ret

puts: ; prints a string to the screen | params: ( string: ds:si ) | returns: void
  push si
  push bx
  push ax
  xor bh, bh
  mov ah, 0x0e
  .loop:
    lodsb
    test al, al
    jz .end
    int 0x10
    jmp .loop
  .end:
    mov bh, [color]
    call setcolor
    pop ax
    pop bx
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

setcolor: ; sets color attribute for entire screen | params: ( colour: bh ) | returns: void
  push ds
  push si
  push ax
  mov ax, 0xb800
  mov ds, ax
  xor si, si
  .loop:
    inc si
    mov ds:[si], bh
    inc si
    cmp si, 0xFA0
    jl .loop
  pop ax
  pop si
  pop ds
  ret

; NOTE: dh and dl are optional, load with 0 to disable
; WARNING: align_right must have enough space to fit entire number, including seperators and signs, otherwise there will be undefined behaviour
fputint32: ; prints an integer to the screen | params: ( int: ecx, seperator: dh, align_right: dl & 0x7F, is_signed: dl & 0x80 ) | returns: void
  push edx
  push ecx
  push bx
  push eax

  test dl, 0x80
  jz .unsigned
  and dl, 0x7F
  cmp ecx, 0
  jge .unsigned
  neg ecx
  or dl, 0x80
  .unsigned:
  test dl, 0x7F
  jz .no_align
  cmp ecx, 0
  jge .not_large
  mov bl, 10
  jmp .align
  .not_large:
  mov bl, 1
  mov eax, 10
  .align_loop:
    cmp ecx, eax
    jl .align
    inc bl
    lea eax, [eax + eax * 4]
    add eax, eax
    jmp .align_loop
  .align:
    test dl, 0x80
    jz .no_neg_align
    dec dl
    .no_neg_align:
    test dh, dh
    jz .no_sep_align
    cmp bl, 9
    jg .sep_align_3
    cmp bl, 6
    jg .sep_align_2
    cmp bl, 3
    jg .sep_align_1
    jmp .no_sep_align
    .sep_align_3:
      dec dl
    .sep_align_2:
      dec dl
    .sep_align_1:
      dec dl
  .no_sep_align:
    sub dl, bl
    test dl, 0x7f
    jle .no_align
    mov al, ' '
    .space_loop:
      call putch
      dec dl
      test dl, 0x7f                                            
      jg .space_loop
  .no_align:
  test ecx, ecx
  jz .zero
  test dl, 0x80
  jz .pos
  mov al, '-'
  call putch
  .pos:
  xor bl, bl
  mov bh, dh
  .loop:
    mov eax, ecx
    mov ecx, 10
    xor edx, edx
    div ecx
    push dx
    inc bl
    mov ecx, eax
    test ecx, ecx
    jz .print
    jmp .loop
  .zero:
    mov al, '0'
    call putch
    jmp .end
  .print:
    mov dh, bh
  .print_loop:
    pop ax
    add al, '0'
    call putch
    dec bl
    test dh, dh
    jz .no_sep
    cmp bl, 9
    je .sep 
    cmp bl, 6
    je .sep
    cmp bl, 3
    je .sep
    jmp .no_sep
  .sep:
    mov al, dh
    call putch
  .no_sep:
    test bl, bl
    jnz .print_loop
  .end:
    pop eax
    pop bx
    pop ecx
    pop edx
    ret

hex2word: ; takes a pointer to a hex string and returns its value | params: ( string: ds:si ) | returns: ( value: cx, invalid: CF )
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

;; NOTE: if terminated (^C), cx = -1, otherwise cx = 0
gets: ; gets a string from the user | params: ( buffer: es:di, max_count: cx ) | returns: ( terminated: cx )
  push di
  push si
  push dx
  push ax

  xor dx, dx
  .loop:
    xor ah, ah
    int 0x16
    cmp al, 8
    je .backspace
    cmp al, 13
    je .end
    cmp al, 10
    je .end
    cmp al, 3
    je .break

    cmp dx, cx
    je .loop
    inc dx

    stosb
    call putch
    jmp .loop
  .backspace:
    test dx, dx
    jz .loop
    mov al, 8
    call putch
    xor al, al
    call putch
    mov al, 8
    call putch
    dec di
    dec dx
    jmp .loop
  .break:
    mov al, '^'
    call putch
    mov al, 'C'
    call putch
    mov cx, -1
    jmp .terminated
  .end:
    xor cx, cx
  .terminated:
    mov byte es:[di], 0
    mov si, endl_msg
    call puts
    pop ax
    pop dx
    pop si
    pop di
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

clear: ; clears the screen | params: void | returns: void
  push dx
  push cx
  push bx
  push ax
  mov ax, 0x0700
  mov bh, [color]
  xor cx, cx
  mov dx, 0x184f
  int 0x10
  mov ah, 0x02
  xor bh, bh
  xor dx, dx
  int 0x10
  pop ax
  pop bx
  pop cx
  pop dx
  ret

%include "src/file_functions.asm"

;; DATA

welcome_msg: db "Welcome to The Boykisser Operating System (BOS) :3", endl, 0
prompt: db ":3 ", 0

help_cmd: db "help", 0
help_msg: db "! means a command is not yet implemented or functionality is limited", endl, endl
          db "GENERIC:", endl
          db "  help - show this message", endl
          db "  clear - clear the screen", endl
          db "  echo - print a message to the screen", endl
          db "  color - change color of screen", endl
          db "  boyfetch - show boykisser and OS info UwU", endl
          db "  restart - restart the operating system", endl
          db "  electrocute - cutely kill the operating system", endl
          db "FILESYSTEM:", endl
          db "  ls - list contents of current working directory", endl,
          db "! cd - change the current working directory", endl
          db "WRITING:", endl
          db "  sp - (scratchpad) temporary spot to write stuff down (does not save)", endl
          db "DEBUG:", endl
          db "  numtest - perform various tests for printing numbers", endl, 0

clear_cmd: db "clear", 0

echo_cmd: db "echo", 0

color_cmd: db "color", 0
color: db default_color
color_msg: db "Usage: color [color]", endl
           db " - [color] is either 1 or 2 hexadecimal digits representing the VGA 16-color", endl
           db "attribute (if 1 digit, background is set to black)", endl, 0

boyfetch_cmd: db "boyfetch", 0
boyfetch_msg: db "    .@.                       .@-", endl
              db "   .@@@@.                   .@@@@.", endl
              db "  .@@@@@@%    @#..         @@@@@@@", endl
              db "  @@@@@@@@@.  =@@@@@:    @@@@@@@@@.", endl
              db " .@@@@@@@@@@@  :=@@@@@%:@@@@@@@@@@.", endl
              db " .@@@@@@@@@+@@@@@@@@@@@@@@@@@@@@@@.    (TO BE EXPANDED)", endl
              db "  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     The Boykisser Operating System (BOS)", endl
              db "  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#     VERSION: v0.1-ALPHA", endl
              db "   @@@@@@@@@@@@@@@@@-   ++.*@@@@@      BUILD: DEV", endl
              db "    @@@.@@.   @@@@@@    @@@+@@@:", endl
              db ".@%-:@@@@@-   @@@@@@.   @@@.@@@@@      SPECS:", endl
              db "  @@@@@=@@@  -@@@@@@@*:@@@@*@@@=         Architecture: x86(_64)", endl
              db "   .@-=@=@@@@@@@@@@@@@@@@-%+@@@          File System:  FAT12", endl
              db "  .@@@@@@@@@@%##:%::@@@@@@@@@@@@#", endl
              db "    .  =@@@@@@@@@@@@@@@@@@.            AUTHOR:", endl
              db "          @=..@@@@@@@@@@                 Name:   Shane Goodrick", endl
              db "            @@@@@@@@@@@@@                GitHub: https://github.com/shappp1", endl
              db "           @@@@@@@@@@@@@@+", endl
              db "            %@@@@@@@@@@@@@.", endl
              db "           .@@@@@@@@@@@@@@@", endl
              db "           @@@@@@@@@@@@@@@@.", endl
              db "           @@@@@@@@@@@@@@@@.", endl
              db "          *@@@@@@@@@@@@@@@@#", endl
              db "          @@@@@@@@@@@@@@@@@@", endl, 0

restart_cmd: db "restart", 0

electrocute_cmd: db "electrocute", 0
electrocute_msg: db "There was a problem while trying to shutdown!", endl, 0

ls_cmd: db "ls", 0
ls_msg: db "Directory for ::/", end2l, 0
dir_msg: db " <DIR>    ", 0

cd_cmd: db "cd", 0
cd_msg: db "Fucking loser can't even use the cd command properly", endl, 0
cd_dot: db ".          ", 0

sp_cmd: db "sp", 0

numtest_cmd: db "numtest", 0

invalid_msg: db "Uh oh you used an invalid command >:3", endl, 0
endl_msg: db endl, 0

command_buffer: times 256 db 0
