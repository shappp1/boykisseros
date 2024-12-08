
.PHONY: run clean

build/main.img: build/boot.bin build/kernel.bin
	dd if=/dev/zero of=build/main.img bs=512 count=2880
	mkfs.fat -F 12 -n "BOYKISSEROS" build/main.img
	dd if=build/boot.bin of=build/main.img conv=notrunc
	mcopy -i build/main.img build/kernel.bin "::KERNEL.BIN"
	mcopy -i build/main.img src/dummy/dummy.txt "::DUMMY.TXT"
	mcopy -i build/main.img src/dummy/folder "::FOLDER"

build/boot.bin: build src/boot.asm
	nasm -f bin -o build/boot.bin src/boot.asm

build/kernel.bin: build src/kernel.asm src/functions/* src/command_handlers/*
	nasm -f bin -o build/kernel.bin src/kernel.asm

build:
	mkdir build

run: build/main.img
	qemu-system-i386 -drive if=floppy,file=build/main.img,format=raw &

clean:
	rm -rf build/
