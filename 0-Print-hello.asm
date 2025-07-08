global _start

section .data
msg db "Hello", 10   ; "Hello\n"
len equ $ - msg      ; length = 6

section .text
_start:
    mov rax, 1        ; syscall number for write
    mov rdi, 1        ; fd = 1 (stdout)
    mov rsi, msg      ; pointer to buffer
    mov rdx, len      ; length of buffer
    syscall           ; make the syscall

    ; exit(0)
    mov rax, 60       ; syscall number for exit
    xor rdi, rdi      ; exit code 0
    syscall
