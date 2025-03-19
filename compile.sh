#!/bin/bash

# assemble source
nasm -f bin -o build/boot.bin src/boot.asm
nasm -f bin -o build/kernel.bin src/kernel.asm

# make 1.44MB floppy disk image
dd if=/dev/zero of=build/main.img bs=512 count=2880
# setup FAT12 on image
mkfs.fat -F 12 -n "BOYKISSEROS" build/main.img
# load bootloader into first 512 bytes of image
dd if=build/boot.bin of=build/main.img conv=notrunc

# copy over some files
mcopy -i build/main.img build/kernel.bin "::BOS.RAW"
mcopy -i build/main.img src/dummy/dummy.txt "::DUMMY.TXT"
mcopy -i build/main.img src/dummy/folder "::FOLDER"