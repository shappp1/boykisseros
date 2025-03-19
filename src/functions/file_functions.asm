;; MEMORY MAP
;
; 0x7C00 BOOTSECTOR 512
; 0x7E00 FAT_BUFFER 4.5K
; 0x9000 DIR_BUFFER 7K
; 0xAC00 FILE_BUFFER 21K
; 0x10000 MAIN_CODE ...
;

read_disk: ; bool read_disk(uint16 lba, char *buffer, uint8 count, uint8 drive_no) ; reads count sectors starting from LBA address
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

read_cluster_chain: ; bool read_cluster_chain(char *buffer, uint16 first_cluster_no) ; reads a chain of FAT12 clusters starting from first_cluster
  push bp
  mov bp, sp
  push ds
  push di
  push dx
  
  mov di, FAT_SEGMENT
  mov ds, di

  mov ax, [bp+8]
  .loop:
    mov di, ax
    sub ax, 2
    xor dx, dx
    mov dl, fs:[SPC]
    mul dx
    add ax, fs:[DATA_START] ; ax = LBA of cluster

    push word fs:[DRIVE]
    push word fs:[SPC] ; # of sectors to read
    push word [bp+6]
    push word [bp+4]
    push ax
    call read_disk
    test al, al
    jz .end ; will keep al = false to indicate error

    xor ax, ax
    mov al, fs:[SPC]
    mul word fs:[BPS]
    add [bp+4], ax

    mov ax, di
    shr di, 1
    add di, ax
    mov dx, [di + FAT_OFFSET]
    test ax, 1
    jz .even
    shr dx, 4
    jmp .check_done
  .even:
    and dx, 0x0FFF
  .check_done:
    mov ax, dx
    cmp dx, 0xFF8
    jl .loop
    mov al, 1
  .end:
    pop dx
    pop di
    pop ds
    pop bp
    ret 6

; dir_handle is the address of the start of a 32-bit directory entry, a dir_handle of 0:0 will load root directory
change_directory: ; bool change_directory(char *dir_handle) ; loads ./dir_handle/ into DIR_SEGMENT:DIR_OFFSET
  push bp
  mov bp, sp
  push ds
  push si
  push dx

  mov si, [bp+4]
  or si, [bp+6]
  jz .read_root

  mov si, [bp+4]
  mov ds, [bp+6]

  xor al, al
  test byte [si+HANDLE_ATTRIB], 0x10 ; check if dir
  jz .end

  mov ax, [si+HANDLE_CLUSTER_LOW]
  test ax, ax
  jz .read_root

  push ax
  push DIR_SEGMENT
  push DIR_OFFSET
  call read_cluster_chain
  jmp .end ; use al from read_cluster_chain

  .read_root:
    ; ax = root entry count in sectors
    mov ax, [ROOT_ENTRIES]
    shl ax, 5
    xor dx, dx
    div word [BPS]
    test dx, dx
    jz .no_inc
    inc ax
    .no_inc:

    ; dx = lba of root dir
    mov dx, [DATA_START]
    sub dx, ax

    push word fs:[DRIVE]
    push ax
    push DIR_SEGMENT
    push DIR_OFFSET
    push dx
    call read_disk
    ; use al from read_disk
  .end:
    pop dx
    pop si
    pop ds
    pop bp

; returns a pointer to the next file in the path after any '/' ( points to 0 is 0 if at end of path ), returns 0:0 if bath is invalid
; buffer[0] is '/' if path starts with '/'
parse_path: ; char *parse_path(char *path_string, char *buffer) ; takes a path string and splits off an 8.3 file name
  push bp
  mov bp, sp
  push es
  push di
  push ds
  push si
  push cx
  push bx

  mov si, [bp+4]
  mov ds, [bp+6]
  mov di, [bp+8]
  mov es, [bp+10]

  ; if path_string is empty, return NULL
  xor dx, dx
  xor ax, ax
  cmp byte [si], 0
  je .end

  ; if path_string[0] is '/', set buffer[0] to '/' and return path_string + 1
  mov byte es:[di], '/'
  mov dx, ds
  mov ax, si
  inc ax
  cmp byte [si], '/'
  je .end

  ; fill buffer with spaces
  mov cx, 11
  mov al, ' '
  rep stosb
  sub di, 11
  
  push si
  xor cx, cx ; cx = length
  .get_length:
    inc cx ; fine because we checked for empty string earlier
    lodsb
    cmp al, '/'
    je .got_length
    test al, al
    jz .got_length
    jmp .get_length
  .got_length:
  pop si

  mov bx, cx
  .get_dot_loc:
    dec bx
    cmp byte [si + bx], '.'
    je .got_dot_loc
    test bx, bx
    jz .got_dot_loc
  .got_dot_loc:

  dec cx
  push cx
  cmp bx, cx
  je .no_ext
  test bx, bx
  jz .no_ext

  ; if extension is too large return NULL
  xor dx, dx
  xor ax, ax
  sub cx, bx
  cmp cx, 3
  jg .end

  push di
  push si
  add di, 8
  add si, bx
  inc si
  .move_ext:
    lodsb
    stosb
    loop .move_ext
  pop si
  pop di
  mov cx, bx
  dec cx

  .no_ext:
  ; if name is too large return NULL
  inc cx
  xor dx, dx
  xor ax, ax
  cmp cx, 8
  jg .end
  
  push si
  .move_name:
    lodsb
    stosb
    loop .move_name
  
  mov dx, ds
  pop ax
  pop bx
  add ax, bx
  add ax, 2

  .end:
    pop bx
    pop cx
    pop si
    pop ds
    pop di
    pop es
    pop bp
    ret 8