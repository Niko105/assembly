global _start ;entry point 

;-------------------------------------------------------------------------------

section .data ;variables
;syscalls equ
syscallOpen  equ 2
syscallWrite equ 1
syscallClose equ 3
syscallExit  equ 60



;-------------------------------------------------------------------------------

section .bss ;unallocated data
buffer resb 20

;-------------------------------------------------------------------------------

section .text ;code
itoa_and_print:
    mov rcx, buffer + 19 ; pointer to the end of buffer
    mov rbx, 10

.convert_loop:
    xor rdx, rdx
    div rbx                ; rax = rax / 10, rdx = rax % 10
    add dl, '0'            ; convert to ASCII
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .convert_loop

    ; calculate length = buffer + 20 - rcx
    mov rdx, buffer + 20
    sub rdx, rcx

    ; write syscall
    mov rax, 1         ; syscall_write
    mov rdi, 1         ; stdout
    mov rsi, rcx       ; pointer to our string
    syscall

    ret


_start:
    mov rax, 5
    call itoa_and_print

    end:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;-------------------------------------------------------------------------------
