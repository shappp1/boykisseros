read_disk: ; reads count sectors starting from LBA address | params: ( lba: ax, buffer: es:bx, count: cl, drive_no: dl ) | returns: ( error: CF set )
  push dx
  push cx
  push ax
  
  push cx
  push dx
  push ds
  xor dx, dx
  mov ds, dx
  div word [0x7c00 + 24] ; sectors per track
  inc dx
  mov cx, dx
  xor dx, dx
  div word [0x7c00 + 26] ; head count
  mov dh, dl
  mov ch, al
  shl ah, 6
  or cl, ah
  pop ds
  pop ax
  mov dl, al
  pop ax

  mov ah, 0x02
  int 0x13
  pop ax
  pop cx
  pop dx
  ret

find_file: ; looks for file in directory buffer | params: ( 8.3: es:di ) | returns ( entry_address: es:di, not_found: CF set )
  push ds
  push si
  push cx
  xor cx, cx
  mov ds, cx
  mov si, directory_buffer
  test byte [si + 11], 0x08
  jz .loop
  .skip:
    add si, 0x20
  .loop:
    cmp byte [si], 0x05
    je .skip
    cmp byte [si], 0xE5
    je .skip
    cmp byte [si], 0
    je .not_found
    push di
    push si
    mov cx, 11
    repe cmpsb
    pop si
    pop di
    je .found
    jmp .skip
  .not_found:
    stc
    jmp .end
  .found:
    mov cx, ds
    mov es, cx
    mov di, si
    clc
  .end:
    pop cx
    pop si
    pop ds
    ret

read_cluster_chain: ; reads a chain of FAT12 clusters starting from first_cluster | params: ( buffer: es:bx, first_cluster: ax )
  push ds
  push dx
  push cx
  push ax
  sub ax, 2
  xor dx, dx
  mov ds, dx
  mov cl, [0x7c00 + 13] ; sectors per cluster
  mov dl, cl
  mul dx
  add ax, 0x21 ; FIX HARDCODED VALUE
  mov dl, [0x7c00 + 36]
  call read_disk
  pop ax
  pop cx
  pop dx
  pop ds
  ret

;; ADDITIONAL INFO
; 
; next_in_path is a pointer to the next file in the path after any '/' ( *next_in_path is 0 if at end of path )
; file_name[0] is 0 if path is invalid or '/' if path starts with '/'
;
parse_path: ; takes a path string and splits of an 8.3 file name | params: ( path: ds:si ) | returns: ( next_in_path: ds:si, file_name: es:di )
  push cx
  push bx
  push ax
  mov di, .name_buffer
  mov byte es:[di], 0
  cmp byte [si], 0
  je .end
  cmp byte [si], '/'
  je .root
  xor bx, bx
  .slash_loop:
    inc bx
    cmp byte [si + bx], 0
    je .no_slash
    cmp byte [si + bx], '/'
    jne .slash_loop
    mov byte [si + bx], 0
  .no_slash:
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
    rep movsb
    pop si
    sub cx, 11
    neg cx
    mov al, ' '
    rep stosb
    mov di, .name_buffer
    lea si, [si + bx + 1]
    jmp .end
  .root:
    mov byte es:[di], '/'
    inc si
  .end:
    pop ax
    pop bx
    pop cx
    ret
  .name_buffer: times 11 db 0