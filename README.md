# The Boykisser Operating System

The Boykisser Operating System (or BOS for short) is an operating system designed by Shane Goodrick that exists solely as an elaborate joke.

# Building

## Linux

First install these requirements using your distro's package manager:
```
make
nasm
qemu
mtools
dosfstools
bochs (optional)
```

then build and run with:
```
./compile.sh
./run.sh
```

Note: you may need to do `chmod +x compile.sh run.sh` if it doesn't work