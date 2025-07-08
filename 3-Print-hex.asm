global _start ;required for the linker to see it

section .data ;variables
a db 10 ;this makes a... weird thing? it's putting a literal byte (10) into a new memory address allocated with the label 'a'

section .text
_start:
    mov rax, 1 ;write()
    mov rdi, 1 ;stdout
    mov rsi, a ;loads the address of "10" into the function, it needs the ADDRESS of the data, not the data
    mov rdx, 1 ;instead for the length of what to print it needs the DATA length, NOT the address
    syscall ;which makes sense, reading from rsi to whatever rdx ends at

    mov rax, 60
    xor rdi, rdi
    syscall
