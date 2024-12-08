%define DATA_START bp-0x02

%define OEM bp+0x03
%define BPS bp+0x0b
%define SPC bp+0x0d
%define RESERVED_SECTORS bp+0x0e
%define FATS bp+0x10
%define ROOT_ENTRIES bp+0x11
%define SECTORS bp+0x13
%define MD bp+0x15
%define SPF bp+0x16
%define SPT bp+0x18
%define HEADS bp+0x1a
%define HIDDEN_SECTORS bp+0x1c
%define LARGE_SECTORS bp+0x20
%define DRIVE bp+0x24
%define SIG bp+0x26
%define VOLID bp+0x27
%define VOLLABEL bp+0x2b
%define FILESYS bp+0x36

%define BASE 0x7c00
%define KERNEL_SEGMENT 0x1000
%define KERNEL_OFFSET 0

%define FAT_SEGMENT 0x7e0
%define FAT_OFFSET 0
%define DIR_SEGMENT 0x900
%define DIR_OFFSET 0
%define FILE_SEGMENT 0xAc0
%define FILE_OFFSET 0

%define DEFAULT_COLOR 0x07

%define endl 10, 13
%define end2l 10, 10, 13
