
.PHONY: run clean

build/main.img: build/boot.bin build/main.bin src/dummy/*
	dd if=/dev/zero of=build/main.img bs=512 count=2880
	mkfs.fat -F 12 -n "BOYKISSEROS" build/main.img
	dd if=build/boot.bin of=build/main.img conv=notrunc
	mcopy -i build/main.img build/main.bin "::MAIN.BIN"
	mcopy -i build/main.img src/dummy/dummy.txt "::DUMMY.TXT"
	mcopy -i build/main.img src/dummy/folder "::FOLDER"

build/boot.bin: build src/boot.asm
	nasm -f bin -o build/boot.bin src/boot.asm

build/main.bin: build src/main.asm src/ch_file.asm src/file_functions.asm
	nasm -f bin -o build/main.bin src/main.asm

build:
	mkdir build

run: build/main.img
	qemu-system-i386 -drive if=floppy,file=build/main.img,format=raw &

clean:
	rm -rf build/
