BITS 64
default rel ;use RIP relative addressing for compatibility, doesn't change code size
global _start ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated
;any extern functions come after this line
extern atoi ;int atoi(rdi=&string, rsi=len), clobbers rax
extern strlen ;int strlen(rdi=&string), no clobber
extern itoa ;int itoa(rdi=int, rsi=&buffer, rdx=&out_start). clobbers rax, rcx, r8, r9, r10
extern atoine ;int atoine(rdi=&string), clobbers rdx
;extern itoaS removed!

;===============================================================================

;zeroing buffers nasm macro, takes 2 inputs (start of the buffer, size in bytes), clobbers rax, rdi, rcx
%macro blankBuffer 2
    mov rcx, %2
    xor rax, rax
    mov rdi, %1
    rep stosb
%endmacro

;zeroing 8 byte aligned buffers nasm macro, takes 2 inputs (start of the buffer, size in qwords), clobbers rax, rdi, rcx
%macro blank8Buffer 2
    mov rcx, %2
    xor rax, rax
    mov rdi, %1
    rep stosq
%endmacro

;===============================================================================

section .data ;user data

;----------------------------------syscalls equ---------------------------------
syscallWrite  equ 1 ;rax=1, rdi=where to (1 for stdout, 2 for stderr), rsi=message, rdx=length
syscallExit   equ 60 ;rax=60, rdi=exit code
;-------------------------------------------------------------------------------

;-----------------------------------variables-----------------------------------
stringToTranslate db "1000",0
newline db 10
;-------------------------------------------------------------------------------

;===============================================================================

section .bss ;unallocated data

stringStart resq 1
string resb 20
buffer resq 1

;===============================================================================

section .text align=16 ;code, aligned on a 16byte boundary

;----------------------------------explanation----------------------------------
;this is a simple test to check if my atoi function works
;it takes a number string with read, and it outputs it as a byte on the terminal
;then it goes through itoa to be printed again!
;-------------------------------------------------------------------------------

_start:
    ; mov rdi, stringToTranslate
    ; call strlen

    ; mov r8, rax

    ; mov rdi, stringToTranslate
    ; mov rsi, r8
    ; call atoi

    mov rbx, 100000000
    .loop:

        ; mov rdi, -9223372036854775808
        ; mov rsi, string
        ; mov rdx, 20
        ; mov rcx, stringStart
        ; call itoaS

        mov rdi, -9223372036854775808
        mov rsi, string
        mov rdx, stringStart
        call itoa

    dec rbx
    test rbx, rbx
    jnz .loop

    

    ; mov rdx, rax
    ; mov rsi, [stringStart]
    ; mov rax, syscallWrite
    ; mov rdi, 1
    ; syscall

    ; mov rsi, newline
    ; mov rax, syscallWrite
    ; mov rdi, 1
    ; mov rdx, 1
    ; syscall

    ; blankBuffer string, 20
    ; blank8Buffer stringStart, 1

    ; mov rdi, stringToTranslate
    ; call atoine

    ; mov qword [buffer], rax

    ; mov rdx, 1
    ; mov rsi, buffer
    ; mov rax, syscallWrite
    ; mov rdi, 1
    ; syscall

    ; mov rsi, newline
    ; mov rax, syscallWrite
    ; mov rdi, 1
    ; mov rdx, 1
    ; syscall

    _exit:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;===============================================================================
