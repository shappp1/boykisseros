;; MEMORY MAP
;
; 0x7C00 BOOTSECTOR 512
; 0x7E00 FAT_BUFFER 4.5K
; 0x9000 DIR_BUFFER 7K
; 0xAC00 FILE_BUFFER 21K
; 0x10000 MAIN_CODE ...
;

read_disk: ; bool read_disk(uint16 lba, char *buffer, uint8 count, uint8 drive_no) ; reads count sectors starting from LBA address and returns true if successful and false if error
  push bp
  mov bp, sp
  push dx
  push cx
  push es
  push bx

  mov ax, [bp+4]
  xor dx, dx
  div word fs:[SPT] ; ax = LBA / SPT
  inc dx
  mov cx, dx ; cl[0..5] = sector
  xor dx, dx
  div word fs:[HEADS] ; ax = cylinder, dx = head
  mov dh, dl
  mov ch, al
  shl ah, 6
  or cl, ah

  mov al, [bp+10]
  mov bx, [bp+6]
  mov es, [bp+8]
  mov dl, [bp+12]
  mov ah, 0x02
  int 0x13 ; al = count, cx = cylinder/sector, dh = head, dl = drive, es:bx = buffer
  mov al, 0
  jc .end ; al = 0 if error
  inc al ; al = 1, success
  .end:
    pop bx
    pop es
    pop cx
    pop dx
    pop bp
    ret 10

; file_name does not have to be \0 terminated, it is simply an 8.3 filename
; returns address of entry in directory buffer, or 0:0 if not found
find_file: ; char *find_file(char *file_name) ; looks for file in directory buffer
  push bp
  mov bp, sp
  push es
  push di
  push ds
  push si
  push cx

  mov si, DIR_SEGMENT
  mov ds, si
  mov si, DIR_OFFSET

  mov di, [bp+4]
  mov es, [bp+6]

  xor ax, ax
  xor dx, dx ; dx:ax = NULL

  sub si, 0x20
  .loop:
    add si, 0x20
    cmp byte [si], 0xE5
    je .loop
    cmp byte [si], 0
    je .end

    push di
    push si
    mov cx, 11
    repe cmpsb
    pop si
    pop di
    jne .loop

  mov ax, si
  mov dx, ds
  .end:
    pop cx
    pop si
    pop ds
    pop di
    pop es
    pop bp
    ret 4

read_cluster_chain: ; bool read_cluster_chain(char *buffer, uint16 first_cluster_no) ; reads a chain of FAT12 clusters starting from first_cluster | params: ( buffer: es:bx, first_cluster: ax ) | returns: ( error: CF set )
  push bp
  mov bp, sp
  push es
  push ds
  push di
  push dx
  push cx
  push bx
  
  mov bx, [bp+4]
  mov es, [bp+6]
  mov ax, [bp+8]

  mov cx, FAT_SEGMENT
  mov ds, cx
  .loop:
    mov di, ax
    sub ax, 2
    mov dl, fs:[SPC]
    xor dh, dh
    mul dx
    add ax, fs:[DATA_START]
    mov cl, fs:[SPC]
    mov dl, fs:[DRIVE]
    push dx
    push cx
    push es
    push bx
    push ax
    call read_disk
    test al, al
    jz .end ; will keep al = false to indicate error
    mov al, cl
    xor ah, ah
    mul word fs:[BPS]
    add bx, ax

    mov ax, di
    shr di, 1
    add di, ax
    mov cx, [di + FAT_OFFSET]
    test ax, 1
    jz .even
    shr cx, 4
    jmp .check_done
  .even:
    and cx, 0xFFF
  .check_done:
    mov ax, cx
    cmp cx, 0xFF8
    jl .loop
    mov ax, 1
  .end:
    pop bx
    pop cx
    pop dx
    pop di
    pop ds
    pop es
    pop bp
    ret 6
 
; next_in_path is a pointer to the next file in the path after any '/' ( *next_in_path is 0 if at end of path )
; file_name[0] is 0 if path is invalid or '/' if path starts with '/'
parse_path: ; takes a path string and splits off an 8.3 file name | params: ( path: ds:si ) | returns: ( next_in_path: ds:si, file_name: es:di )
  push dx
  push cx
  push bx
  push ax
  mov al, ' '
  mov di, .name_buffer
  mov byte es:[di], 0
  cmp byte [si], 0
  je .end
  cmp byte [si], '/'
  je .root
  xor bx, bx
  mov dx, 1
  .slash_loop:
    inc bx
    cmp byte [si + bx], 0
    je .no_slash
    inc dx
    cmp byte [si + bx], '/'
    jne .slash_loop
    mov byte [si + bx], 0
  .no_slash:
    add di, 8
    mov cx, 3
    rep stosb
    mov di, .name_buffer
    dec bx
    test bx, bx
    jz .no_ext
  .loop:
    dec bx
    test bx, bx
    jz .no_ext
    cmp byte [si + bx], '.'
    jne .loop
    ; code for with ext
    add di, 8
    mov byte [si + bx], 0
    mov cx, bx
  .ext:
    inc bx
    cmp byte [si + bx], 0
    jne .ext
    push si
    add si, cx
    inc si
    sub cx, bx
    neg cx
    cmp cx, 3
    jle .no_truncate_ext
    mov cx, 3
  .no_truncate_ext:
    mov bx, cx
    rep movsb
    mov cx, bx
    pop si
    sub cx, 3
    neg cx
    rep stosb
    xor bx, bx
    mov di, .name_buffer
  .no_ext: ; bx = 0  di = name_buffer
    inc bx
    cmp byte [si + bx], 0
    jne .no_ext
    mov cx, bx
    cmp cx, 8
    jle .no_truncate_name
    mov cx, 8
  .no_truncate_name:
    push si
    mov bx, cx
    rep movsb
    mov cx, bx
    pop si
    sub cx, 8
    neg cx
    rep stosb
    mov di, .name_buffer
    add si, dx
    jmp .end
  .root:
    mov byte es:[di], '/'
    inc si
  .end:
    pop ax
    pop bx
    pop cx
    pop dx
    ret
  .name_buffer: times 12 db 0