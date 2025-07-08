mkdir build 2> /dev/null
nasm -f elf64 $1 -o build/program.o
ld build/program.o -o program -L. -lNiko
