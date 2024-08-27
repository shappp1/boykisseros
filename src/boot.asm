%define endl 10, 13
%define FAT_buffer 0x7e00
%define directory_buffer 0x9000
%define file_segment 0x1000

[BITS 16]
[ORG 0x7c00]

;; BPB
jmp short start
nop
oem: db "boys uwu" ; oem (8 bytes)
bytes_per_sector: dw 0x200 ; bytes per sector
sectors_per_cluster: db 1 ; sectors per cluster
reserved_sectors: dw 1 ; reserved sectors
FAT_count: db 2 ; # of FATs
root_entries_count: dw 0xe0 ; # of root directory entries
sector_count: dw 0xb40 ; # of sectors
media_descriptor: db 0xf0 ; media descriptor type
sectors_per_FAT: dw 9 ; sectors per FAT
sectors_per_track: dw 18 ; sectors per track
head_count: dw 2 ; # of heads/sides
hidden_sector_count: dd 0 ; # of hidden sectors
large_sector_count: dd 0 ; large sector count

;; FAT12
drive_no: db 0 ; drive number
reserved: db 0 ; Windows NT flags
signature: db 0x29 ; signature
serial_no: db 0x0E, 0x0B, 0x12, 0x07; serial number (4 bytes)
volume_label: db "BOYKISSEROS" ; volume label (11 bytes)
identifier: db "FAT12   " ; system identifier (8 bytes)

;; CODE

start:
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov ss, ax
  mov sp, 0x7c00

  jmp 0:main
main:
  ; gets [drive_no], [sectors_per_track], and [head_count] from BIOS
  mov [drive_no], dl
  push es
  xor di, di
  mov ah, 0x8
  int 0x13
  jc disk_error
  pop es
  and cl, 0x3F
  xor ch, ch
  mov [sectors_per_track], cx
  inc dh
  mov [head_count], dh

  ; read root directory
  mov ax, [root_entries_count]
  shl ax, 5
  xor dx, dx
  div word [bytes_per_sector]
  test dx, dx
  jz .no_inc
  inc ax
.no_inc:
  mov cx, ax
  mov ax, [sectors_per_FAT]
  mul byte [FAT_count]
  add ax, [reserved_sectors]
  mov bp, ax
  add bp, cx
  mov bx, directory_buffer
  mov dl, [drive_no]
  call read_disk

  ; look for file
  mov di, bx
  xor bx, bx
.find_file:
  mov si, file_name
  mov cx, 11
  push di
  repe cmpsb
  pop di
  je .found_file
  add di, 32
  inc bx
  cmp bx, [root_entries_count]
  je disk_error
  jmp .find_file
.found_file:
  mov di, [di + 26]

  ; read FAT
  mov ax, [reserved_sectors]
  mov bx, FAT_buffer
  mov cx, [sectors_per_FAT]
  call read_disk

  ; read file
  mov bx, file_segment
  mov es, bx
  xor bx, bx
.read_file_loop: ; current_cluster: di ; start of data space: bp
  mov ax, di
  sub ax, 2
  mov dl, [sectors_per_cluster]
  xor dh, dh
  mul dx
  add ax, bp
  mov dl, [drive_no]
  mov cl, [sectors_per_cluster]
  call read_disk
  mov al, cl
  xor ah, ah
  mul word [bytes_per_sector]
  add bx, ax

  mov si, di
  shr si, 1
  add si, di
  add si, FAT_buffer
  mov ax, [si]
  test di, 1
  jz .even

  shr ax, 4
  jmp .check_next_cluster
.even:
  and ax, 0xFFF
.check_next_cluster:
  cmp ax, 0xFF8
  jge .read_finish

  mov di, ax
  jmp .read_file_loop

.read_finish:
  mov bx, file_segment
  mov ds, bx
  mov es, bx
  jmp file_segment:0

disk_error:
  mov si, error_msg
  call puts

halt:
  cli
  hlt
  jmp halt

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

read_disk: ; reads count sectors starting from LBA address | params: ( lba: ax, buffer: es:bx, count: cl, drive_no: dl ) | returns: void
  push ax
  push cx
  
  push cx
  push dx
  xor dx, dx
  div word [sectors_per_track]
  inc dx
  mov cx, dx
  xor dx, dx
  div word [head_count]
  mov dh, dl
  mov ch, al
  shl ah, 6
  or cl, ah
  pop ax
  mov dl, al
  pop ax

  mov ah, 2
  .loop:
    push ax
    mov ah, 0x2
    int 0x13
    pop ax
    jnc .end
    test ah, ah
    jz disk_error
    push ax
    xor ah, ah
    int 0x13
    pop ax
    jc disk_error
    dec ah
    jmp .loop
    
  .end:
    pop cx
    pop ax
    ret

;; DATA

error_msg: db "Silly little disk error :3", endl, 0
file_name: db "MAIN    BIN"

times 510-($-$$) db 0
dw 0xaa55