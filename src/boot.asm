%include "src/defines.asm"

[ORG BASE]
[BITS 16]

;; BPB
jmp short start
nop
db "boys uwu" ; oem (8 bytes)
dw 0x200 ; bytes per sector
db 1 ; sectors per cluster
dw 1 ; reserved sectors
db 2 ; # of FATs
dw 0xe0 ; # of root directory entries
dw 0xb40 ; # of sectors
db 0xf0 ; media descriptor type
dw 9 ; sectors per FAT
dw 18 ; sectors per track
dw 2 ; # of heads/sides
dd 0 ; # of hidden sectors
dd 0 ; large sector count

;; FAT12
db 0 ; drive number
db 0 ; Windows NT flags
db 0x29 ; signature
db 0x0E, 0x0B, 0x12, 0x07; serial number (4 bytes)
db "BOYKISSEROS" ; volume label (11 bytes)
db "FAT12   " ; system identifier (8 bytes)

;; CODE

start:
  jmp 0:boot
boot:
  ; setup segment registers
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov fs, ax ; use fs for all header defines
  mov ss, ax
  mov sp, BASE
  mov bp, sp

  ; get some drive parameters
  mov [DRIVE], dl

  xor di, di
  mov ah, 0x08
  int 0x13
  jc disk_error

  and cx, 0x3F
  mov [SPT], cx

  inc dh
  mov [HEADS], dh

  ; read FAT
  mov ax, [RESERVED_SECTORS] ; ax = LBA of FAT

  mov bx, FAT_SEGMENT
  mov es, bx
  mov bx, FAT_OFFSET ; es:bx = FAT buffer location

  mov cl, [SPF] ; cl (count) = sectors/FAT

  mov dl, [DRIVE] ; dl = ...drive (who would've guessed)

  call read_disk
  jc disk_error

  ; read root directory
  mov ax, [ROOT_ENTRIES]
  shl ax, 5
  xor dx, dx
  div word [BPS]
  test dx, dx
  jz .no_inc
  inc ax
  
.no_inc:
  mov cl, al ; cl = count = ceil( ROOT_ENTRIES * 32 / BPS )

  mov ax, [SPF]
  mul byte [FATS]
  add ax, [RESERVED_SECTORS] ; ax = LBA of root directory = RESERVED_SECTORS + SPF * FATS

  xor ch, ch
  mov bx, ax
  add bx, cx ; bx = LBA of root directory + count
  push bx ; DATA_START = bx

  mov bx, DIR_SEGMENT
  mov es, bx
  mov bx, DIR_OFFSET ; es:bx = root directory buffer location

  mov dl, [DRIVE] ; dl = drive

  call read_disk
  jc disk_error

  ; find file in root directory
  mov di, bx ; di = DIR_OFFSET
.find_file_loop:
  cmp byte es:[di], 0
  jz disk_error ; if name[0] = 0 then we've reached end of root directory

  mov si, file_name
  mov cx, 11

  push di
  repe cmpsb ; compare ds:si (file_name) with es:di (root dir entry)
  pop di

  je .found_file
  add di, 32
  jmp .find_file_loop
  
.found_file:
  mov di, es:[di+26] ; di = first cluster number


  ; read file from disk
  mov bx, KERNEL_SEGMENT
  mov es, bx
  mov bx, KERNEL_OFFSET ; es:bx = kernel buffer
.read_file_loop:
  mov ax, di
  sub ax, 2 ; ax = cluster number - 2
  mov dl, [SPC]
  xor dh, dh
  mul dx ; ax = cluster offset in sectors
  add ax, [DATA_START] ; ax = LBA of cluster

  mov cl, [SPC] ; cl = count = sectors/cluster

  mov dl, [DRIVE] ; dl = drive

  call read_disk
  jc disk_error

  mov al, cl
  xor ah, ah
  mul word [BPS]
  add bx, ax ; buffer += bytes read

  mov si, di
  shr si, 1
  add si, di ; si = floor( (current cluster) * 1.5 )
  mov ax, FAT_SEGMENT
  push ds
  mov ds, ax
  mov ax, ds:[si + FAT_OFFSET] ; ax = next cluster before processing
  pop ds
  
  test di, 1
  jz .even
  shr ax, 4 ; if current cluster odd shift right 4
  jmp .check_done
.even:
  and ax, 0xFFF ; if current cluster even and with 0xFFF
.check_done:
  mov di, ax
  cmp ax, 0xFF8 ; if cluster >= 0xFF8 then no more to read
  jl .read_file_loop

.goto_file:
  mov bx, KERNEL_SEGMENT
  mov ds, bx
  mov es, bx
  jmp KERNEL_SEGMENT:KERNEL_OFFSET

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

read_disk: ; reads count sectors starting from LBA address | params: ( lba: ax, buffer: es:bx, count: cl, drive_no: dl ) | returns: ( error: CF set )
  push dx
  push cx
  push ax
  
  ; convert LBA to CHS
  push cx
  push dx

  xor dx, dx
  div word [SPT]
  inc dx
  mov cx, dx ; cx = LBA % SPT + 1
  xor dx, dx
  div word [HEADS] ; ax = LBA / SPT / HEADS
  mov dh, dl ; dh = ( LBA / SPT ) % HEADS
  mov ch, al ; ch = ax[0..7]
  shl ah, 6 
  or cl, ah ; highest 2 bits of cl = ax[8..9]
  pop ax
  mov dl, al ; dl = drive_no
  pop ax ; al = count

  ; read disk
  mov ah, 0x02
  int 0x13

  pop ax
  pop cx
  pop dx
  ret

;; DATA

error_msg: db "Silly little disk error :3", endl, 0
file_name: db "BOS     SYS"

times 510-($-$$) db 0
dw 0xaa55