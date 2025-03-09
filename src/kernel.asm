%include "src/defines.asm"

[ORG KERNEL_SEGMENT*16+KERNEL_OFFSET]
[BITS 16]
[map all build/kernel.map]

;; CODE

call clear
push ds
push str_welcome
call puts

command_loop:
  push ds
  push str_prompt
  call puts

  mov si, command_buffer

  ; gets(command_buffer, 255)
  push 0xFF
  push ds
  push si
  call gets

  ; if terminated then jump to command_loop
  test al, al
  jnz command_loop

  ; if empty then jump to command_loop
  cmp byte [si], 0
  je command_loop

  ; split_args(command_buffer)
  push ds
  push si
  call split_args
  mov bx, ax ; bx = &args

  ; touppers(command_buffer)
  push ds
  push si
  call to_upper

  xor cx, cx
  mov di, str_commands
  .loop:
    cmp byte [di], 0
    je ch_invalid
    
    push ds
    push di
    call split_args
    mov dx, ax ; dx = &next

    push ds
    push di
    push ds
    push si
    call cmps

    mov di, dx
    cmp byte [di], 0
    je .no_restore
    ; replace 0 with space in str_commands
    mov byte [di - 1], ' '
  .no_restore:
    test al, al
    jnz .found

    inc cx
    inc cx
    jmp .loop

  .found:
    mov di, cx
    jmp [command_vector + di]

halt:
  cli
  hlt
  jmp halt

;; COMMAND VECTORS

%include "src/command_handlers/generic_ch.asm"
%include "src/command_handlers/power_ch.asm"
%include "src/command_handlers/file_ch.asm"
%include "src/command_handlers/debug_ch.asm"

ch_invalid:
  push ds
  push str_invalid
  call puts
  jmp command_loop

;; FUNCTIONS
;    Arguments to a function are pushed to the stack in reverse order
;    All registers are callee saved unless they are being used to return a value
;    Stack is cleaned by the callee
;    1-byte data types are pushed as 2-bytes, the highest byte is ignored
;    for pointers, push segment first, then offset
;    for bools, 0 is false, and any non-zero value is true (typically 1)
;    1-byte values are returned in al
;    2-byte values are returned in ax
;    pointers (and 4-byte values) are returned in dx:ax

%include "src/functions/IO_functions.asm"
%include "src/functions/string_functions.asm"
%include "src/functions/screen_functions.asm"
%include "src/functions/file_functions.asm"

;; READONLY DATA

str_commands:
  db "HELP CLEAR ECHO COLOR BOYFETCH RESTART ELECTROCUTE LS CD TYPE SP NUMTEST", 0
command_vector:
  dw ch_help, ch_clear, ch_echo, ch_color, ch_boyfetch, ch_restart, ch_electrocute, ch_ls, ch_cd, ch_type, ch_sp, ch_numtest

str_prompt: db ":3 ", 0
str_welcome: db "Welcome to The Boykisser Operating System (BOS) :3", endl, 0

str_help_sections: db "Usage: help [section] (page)", endl
                   db "Sections:", endl
                   db "  GENERIC   FILE   WRITING   DEBUG", endl, 0
str_generic: db "GENERIC", 0
str_file: db "FILE", 0
str_writing: db "WRITING", 0
str_debug: db "DEBUG", 0

str_help_generic: db "GENERIC | page 1 of 1", endl
                  db "  help - show this message", endl
                  db "  clear - clear the screen", endl
                  db "  echo - print a message to the screen", endl
                  db "! color - change color of screen", endl
                  db "  boyfetch - show boykisser and OS info UwU", endl
                  db "  restart - restart the operating system", endl
                  db "  electrocute - cutely kill the operating system", endl, 0

str_help_file: db "FILE | page 1 of 1", endl
               db "  ls - list contents of current working directory", endl
               db "! cd - change the current working directory", endl
               db "! type - print the contents of a file", endl, 0

str_help_writing: db "WRITING | page 1 of 1", endl
                  db "  sp - (scratchpad) temporary spot to write stuff down (does not save)", endl, 0

str_help_debug: db "DEBUG | page 1 of 1", endl
                db "  numtest - perform various tests for printing numbers", endl, 0

str_color: db "The color command is currently unavailable", endl, 0
; str_color: db "Usage: color [color]", endl
;            db " - [color] is either 1 or 2 hexadecimal digits representing the VGA 16-color", endl
;            db "attribute (if 1 digit, background is set to black)", endl, 0

str_boyfetch: db "    .@.                       .@-", endl
              db "   .@@@@.                   .@@@@.", endl
              db "  .@@@@@@%    @#..         @@@@@@@", endl
              db "  @@@@@@@@@.  =@@@@@:    @@@@@@@@@.", endl
              db " .@@@@@@@@@@@  :=@@@@@%:@@@@@@@@@@.", endl
              db " .@@@@@@@@@+@@@@@@@@@@@@@@@@@@@@@@.", endl
              db "  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     The Boykisser Operating System (BOS)", endl
              db "  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#     VERSION:  v0.1-ALPHA", endl
              db "   @@@@@@@@@@@@@@@@@-   ++.*@@@@@      CODENAME: BEGINNINGS", endl
              db "    @@@.@@.   @@@@@@    @@@+@@@:", endl
              db ".@%-:@@@@@-   @@@@@@.   @@@.@@@@@      SPECS:", endl
              db "  @@@@@=@@@  -@@@@@@@*:@@@@*@@@=         Architecture: x86", endl
              db "   .@-=@=@@@@@@@@@@@@@@@@-%+@@@          File System:  FAT12", endl
              db "  .@@@@@@@@@@%##:%::@@@@@@@@@@@@#", endl
              db "    .  =@@@@@@@@@@@@@@@@@@.            AUTHOR:", endl
              db "          @=..@@@@@@@@@@                 Name:      Shane Goodrick", endl
              db "            @@@@@@@@@@@@@                GitHub:    https://github.com/shappp1", endl
              db "           @@@@@@@@@@@@@@+               Help From: https://github.com/theridev", endl
              db "            %@@@@@@@@@@@@@.", endl
              db "           .@@@@@@@@@@@@@@@", endl
              db "           @@@@@@@@@@@@@@@@.", endl
              db "           @@@@@@@@@@@@@@@@.", endl
              db "          *@@@@@@@@@@@@@@@@#", endl
              db "          @@@@@@@@@@@@@@@@@@", endl, 0


str_electrocute: db "There was a problem while trying to shutdown!", endl, 0

str_ls: db "Directory for ::/", end2l, 0
str_dir: db " <DIR>    ", 0

str_cd_type_err: db "Fucking loser can't even use the cd/type command properly", endl, 0

str_invalid: db "Uh oh you used an invalid command >:3", endl, 0
str_endl: db endl, 0

;; READ/WRITE DATA

; color: db DEFAULT_COLOR

path_buffer: times 128 db 0
command_buffer: times 256 db 0