%define BASE           0x7C00
%define KERNEL_SEGMENT 0x1000
%define KERNEL_OFFSET  0x0000
%define FAT_SEGMENT    0x07E0
%define FAT_OFFSET     0x0000
%define DIR_SEGMENT    0x0900
%define DIR_OFFSET     0x0000
%define FILE_SEGMENT   0x0AC0
%define FILE_OFFSET    0x0000

%define DATA_START       BASE-0x02
%define OEM              BASE+0x03
%define BPS              BASE+0x0B
%define SPC              BASE+0x0D
%define RESERVED_SECTORS BASE+0x0E
%define FATS             BASE+0x10
%define ROOT_ENTRIES     BASE+0x11
%define SECTORS          BASE+0x13
%define MD               BASE+0x15
%define SPF              BASE+0x16
%define SPT              BASE+0x18
%define HEADS            BASE+0x1A
%define HIDDEN_SECTORS   BASE+0x1C
%define LARGE_SECTORS    BASE+0x20
%define DRIVE            BASE+0x24
%define SIG              BASE+0x26
%define VOLID            BASE+0x27
%define VOLLABEL         BASE+0x2B
%define FILESYS          BASE+0x36

%define HANDLE_FILE_NAME     0x00
%define HANDLE_ATTRIB        0x0B
%define HANDLE_RESERVED      0x0C
%define HANDLE_CREATION_CS   0x0D
%define HANDLE_CREATION_TIME 0x0E
%define HANDLE_CREATION_DATE 0x10
%define HANDLE_ACCESSED_DATE 0x12
%define HANDLE_CLUSTER_HIGH  0x14
%define HANDLE_MODIFIED_TIME 0x16
%define HANDLE_MODIFIED_DATE 0x18
%define HANDLE_CLUSTER_LOW   0x1A
%define HANDLE_FILE_SIZE     0x1C

; %define DEFAULT_COLOR 0x07

%define endl  10, 13
%define end2l 10, 10, 13