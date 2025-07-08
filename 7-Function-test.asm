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
buffer resq 1 ;prepare a 64bit buffer

;-------------------------------------------------------------------------------

section .text ;code
sum10and20: ; int sum10and20(int, int)
    push rbp ;save the old base pointer to restore it later (for nested functions i believe)
    mov rbp, rsp ;set it as the current stack pointer (for obvious reasons)
    sub rsp, 16 ;allocate 2 variables on the stack

    mov qword [rbp-8], 10 ;first var is now 10
    mov qword [rbp-16], 22 ;second is now 22 
    ;there's no reason for these to be on the stack, but i like playing with it
    ;stack frame is actually addressed weirdly, instead of being +n it's -8-n, since it's not the stack pointer

    ;do function stuff!
    xor rax, rax ;zero it
    add rax, rdi
    add rax, rsi
    add rax, [rbp-8]
    add rax, [rbp-16]
    ;into rax because that's the "return" spot apparently

    mov rsp, rbp ;restore the stack pointer, deallocation is no longer necessary!
    pop rbp ;and restore the base pointer
    ret ;aand return

_start:
    mov rdi, 5 ;first argument
    mov rsi, 10 ;second argument
    call sum10and20 ;call
    mov [buffer], rax ;save the output for syscall

    ;outputting, with the write syscall
    mov rax, syscallWrite ;still 1
    mov rdi, 1 ;stdout
    mov rsi, buffer ;the uh.. the number
    mov rdx, 8 ;output the full thing
    syscall ;call!

    end:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;-------------------------------------------------------------------------------
