global _start

section .data


section .bss


section .text
_start:
    ;so fun bit about x86-64, 128 bit numbers exist and they're made with RDX:RAX
    mov rdx, 70 ;so you start by loading a number into rdx
    cqo ;then you make the sign go into rax, and bam, you have the 128 bit number!
    ;cqo does sign extension, meaning it gets a 64 bit signed number into a 128 bit signed number, it's neat
    ;set rdx to 0 (xor rdx, rdx) if you want an unsigned

    mov rax, 60
    xor rdi, rdi
    syscall