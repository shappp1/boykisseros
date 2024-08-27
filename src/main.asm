%define endl 10, 13
%define end2l 10, 10, 13
%define FAT_buffer 0x7e00
%define directory_buffer 0x9000

%define root_entries_count 0x7c0e

%define colour 0x07

[ORG 0x10000]
[BITS 16]

;; CODE

mov bh, colour
call clear
mov si, welcome_msg
call puts

command_loop:
  mov si, prompt
  call puts

  mov di, command_buffer
  mov cx, 0xFF
  call gets
  mov si, di
  call splitargs
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

  mov si, boyfetch_cmd
  call cmps
  jc ch_boyfetch

  mov si, restart_cmd
  call cmps
  jc ch_restart

  mov si, ls_cmd
  call cmps
  jc ch_ls

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
  mov bh, colour
  call clear
  jmp command_loop

ch_echo:
  mov si, ax
  call puts
  mov si, endl_msg
  call puts
  jmp command_loop

ch_boyfetch:
  mov si, boyfetch_msg
  call puts
  jmp command_loop

ch_restart:
  mov word ss:[0x0472], 0
  jmp 0xf000:0xfff0

%include "src/ch_file.asm"

ch_invalid:
  mov si, invalid_msg
  call puts
  jmp command_loop

;; FUNCTIONS

puts: ; prints a string to the screen | params: ( string: ds:si ) | returns: void
  push si
  push ax
  push bx
  xor bh, bh
  mov ah, 0x0e
  .loop:
    lodsb
    test al, al
    jz .end
    int 0x10
    jmp .loop
  .end:
    pop bx
    pop ax
    pop si
    ret

putint: ; prints an integer to the screen | params: ( int: cx ) | returns: void
  push dx
  push cx
  push bx
  push ax

  xor bx, bx
  cmp cx, 0
  je .zero
  jg .loop
  neg cx
  mov ah, 0x0e
  mov al, '-'
  int 0x10
  .loop:
    mov ax, cx
    mov cx, 10
    xor dx, dx
    div cx
    push dx
    inc bl
    mov cx, ax
    test cx, cx
    jz .print
    jmp .loop
  .zero:
    mov ah, 0x0e
    mov al, '0'
    int 0x10
    jmp .end
  .print:
    pop ax
    mov ah, 0x0e
    add al, '0'
    int 0x10
    dec bl
    test bl, bl
    jnz .print
  .end:
    pop ax
    pop bx
    pop cx
    pop dx
    ret

gets: ; gets a string from the user | params: ( buffer: es:di, max_count: cx ) | returns: void
  push di
  push dx
  push cx
  push bx
  push ax

  xor bx, bx
  xor dx, dx
  .loop:
    xor ah, ah
    int 0x16
    cmp ah, 0x0e
    je .backspace
    cmp ah, 0x1c
    je .end

    cmp dx, cx
    je .loop
    inc dx

    stosb
    mov ah, 0x0e
    int 0x10
    jmp .loop
  .backspace:
    test dx, dx
    jz .loop
    mov ah, 0x0e
    mov al, 8
    int 0x10
    xor al, al
    int 0x10
    mov al, 8
    int 0x10
    dec di
    dec dx
    jmp .loop
  .end:
    mov byte es:[di], 0

    mov ah, 0x0e
    mov al, 10
    int 0x10
    mov al, 13
    int 0x10

    pop ax
    pop bx
    pop cx
    pop dx
    pop di
    ret

splitargs: ; looks for the first space in a string, changes it to 0, and returns address of character after space | params: ( command: ds:si ) | returns: ( arg: ds:si )
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

clear: ; clears the screen | params: ( colour: bh ) | returns: void
  push dx
  push cx
  push ax
  mov ax, 0x0700
  xor cx, cx
  mov dx, 0x184f
  int 0x10
  mov ah, 0x02
  mov ch, bh
  xor bh, bh
  xor dx, dx
  int 0x10
  mov bh, ch
  pop ax
  pop cx
  pop dx
  ret

;; DATA

welcome_msg: db "Welcome to The Boykisser Operating System (BOS) :3", endl, 0
prompt: db ":3 ", 0

help_cmd: db "help", 0
help_msg: db "GENERIC:", endl
          db "  help - show this message", endl
          db "  clear - clear the screen", endl
          db "  echo - print a message to the screen"
          db "  boyfetch - show boykisser and OS info UwU", endl
          db "  restart - restart the operating system", endl
          db "FILESYSTEM:", endl
          db "  ls - list contents of current working directory", endl, 0

clear_cmd: db "clear", 0

echo_cmd: db "echo", 0

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

ls_cmd: db "ls", 0
ls_msg: db "Directory for ::/", end2l, 0
dir_msg: db " <DIR>    ", 0

invalid_msg: db "Uh oh you used an invalid command >:(", endl, 0
endl_msg: db endl, 0

command_buffer: times 256 db 0