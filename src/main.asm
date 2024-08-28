%define endl 10, 13
%define end2l 10, 10, 13
%define FAT_buffer 0x7e00
%define directory_buffer 0x9000

%define root_entries_count 0x7c0e

%define colour 0x1f

[ORG 0x10000]
[BITS 16]

;; CODE

call clear
mov si, welcome_msg
call puts

command_loop:
  mov bh, colour
  call setcolor
  mov si, prompt
  call puts

  mov di, command_buffer
  mov cx, 76
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

ch_boyfetch:
  mov si, boyfetch_msg
  call puts
  jmp command_loop

ch_restart:
  mov word ss:[0x0472], 0
  jmp 0xf000:0xfff0

%include "src/ch_file.asm"

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
    mov ah, 0x0e
    mov al, ' '
    xor bh, bh
    .space_loop:
      int 0x10
      dec dl
      test dl, 0x7f                                            
      jg .space_loop
  .no_align:
  test ecx, ecx
  jz .zero
  test dl, 0x80
  jz .pos
  mov ah, 0x0e
  mov al, '-'
  xor bh, bh
  int 0x10
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
    mov ah, 0x0e
    mov al, '0'
    int 0x10
    jmp .end
  .print:
    mov dh, bh
    xor bh, bh
  .print_loop:
    pop ax
    mov ah, 0x0e
    add al, '0'
    int 0x10
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
    int 0x10
  .no_sep:
    test bl, bl
    jnz .print_loop
  .end:
    pop eax
    pop bx
    pop ecx
    pop edx
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

clear: ; clears the screen | params: void | returns: void
  push dx
  push cx
  push bx
  push ax
  mov ax, 0x0700
  xor bh, bh
  xor cx, cx
  mov dx, 0x184f
  int 0x10
  mov ah, 0x02
  xor dx, dx
  int 0x10
  pop ax
  pop bx
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
          db "  echo - print a message to the screen", endl
          db "  boyfetch - show boykisser and OS info UwU", endl
          db "  restart - restart the operating system", endl
          db "FILESYSTEM:", endl
          db "  ls - list contents of current working directory", endl
          db "DEBUG:", endl
          db "  numtest - performs various tests for printing numbers", endl, 0

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

numtest_cmd: db "numtest", 0

invalid_msg: db "Uh oh you used an invalid command >:3", endl, 0
endl_msg: db endl, 0

command_buffer: times 256 db 0