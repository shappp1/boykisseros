%include "src/defines.asm"

[ORG KERNEL_SEGMENT*16+KERNEL_OFFSET]
[BITS 16]
[map all build/kernel.map]

;; CODE

call clear
mov si, str_welcome
call puts

command_loop:
  mov si, str_prompt
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
  mov ax, si ; ax = pointer to first byte of arguments

  mov si, cmd_help
  call cmps
  jc ch_help

  mov si, cmd_clear
  call cmps
  jc ch_clear

  mov si, cmd_echo
  call cmps
  jc ch_echo

  mov si, cmd_color
  call cmps
  jc ch_color

  mov si, cmd_boyfetch
  call cmps
  jc ch_boyfetch

  mov si, cmd_restart
  call cmps
  jc ch_restart

  mov si, cmd_electrocute
  call cmps
  jc ch_electrocute

  mov si, cmd_ls
  call cmps
  jc ch_ls

  mov si, cmd_cd
  call cmps
  jc ch_cd

  mov si, cmd_type
  call cmps
  jc ch_type

  mov si, cmd_sp
  call cmps
  jc ch_sp

  mov si, cmd_numtest
  call cmps
  jc ch_numtest

  jmp ch_invalid

halt:
  cli
  hlt
  jmp halt

;; COMMAND HANDLERS

%include "src/command_handlers/generic_ch.asm"
%include "src/command_handlers/power_ch.asm"
%include "src/command_handlers/file_ch.asm"
%include "src/command_handlers/debug_ch.asm"

ch_invalid:
  mov si, str_invalid
  call puts
  jmp command_loop

;; FUNCTIONS

%include "src/functions/IO_functions.asm"
%include "src/functions/string_functions.asm"
%include "src/functions/screen_functions.asm"
%include "src/functions/file_functions.asm"

;; COMMANDS

cmd_help: db "help", 0
cmd_clear: db "clear", 0
cmd_echo: db "echo", 0
cmd_color: db "color", 0
cmd_boyfetch: db "boyfetch", 0
cmd_restart: db "restart", 0
cmd_electrocute: db "electrocute", 0

cmd_ls: db "ls", 0
cmd_cd: db "cd", 0
cmd_type: db "type", 0

cmd_sp: db "sp", 0

cmd_numtest: db "numtest", 0

;; DATA

color: db DEFAULT_COLOR
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
                  db "  color - change color of screen", endl
                  db "  boyfetch - show boykisser and OS info UwU", endl
                  db "  restart - restart the operating system", endl
                  db "  electrocute - cutely kill the operating system", endl, 0

str_help_file: db "! means a command is not yet implemented or functionality is limited", endl
               db "FILE | page 1 of 1", endl
               db "  ls - list contents of current working directory", endl
               db "! cd - change the current working directory", endl
               db "! type - print the contents of a file", endl, 0

str_help_writing: db "WRITING | page 1 of 1", endl
                  db "  sp - (scratchpad) temporary spot to write stuff down (does not save)", endl, 0

str_help_debug: db "DEBUG | page 1 of 1", endl
                db "  numtest - perform various tests for printing numbers", endl, 0

str_color: db "Usage: color [color]", endl
           db " - [color] is either 1 or 2 hexadecimal digits representing the VGA 16-color", endl
           db "attribute (if 1 digit, background is set to black)", endl, 0

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

path_buffer: times 128 db 0
command_buffer: times 256 db 0