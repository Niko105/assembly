global _start ;entry point 

;-------------------------------------------------------------------------------

section .data ;variables
;syscalls equ
syscallRead  equ 0 ;rax=0 returns how many bytes were read, rdi=where from (0 is stdin), rsi=where to, rdx=size
syscallOpen  equ 2 ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=mode
syscallWrite equ 1 ;rax=1, rdi=where to (1 is stdout, 2 stderr), rsi=message, rdx=length
syscallClose equ 3 ;rax=3, rdi=fd
syscallExit  equ 60 ;rax=60, rdi=exit code
syscallExec  equ 59 ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap  equ 9 ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap equ 11 ;rax=11, rdi=address, rsi=size


;-------------------------------------------------------------------------------

section .bss ;unallocated data
buffer resb 21 ;21 chars and null terminator

;-------------------------------------------------------------------------------

section .text ;code
_start:
    mov rax, syscallRead ;read()
    mov rdi, 0 ;stdin
    mov rsi, buffer ;allocated as 21 bytes
    mov rdx, 20 ;20 bytes
    syscall ;read from stdin and place 20 bytes into buffer

    mov rbx, rax ;save the number of bytes read

    mov byte [buffer + rbx], 10 ;append a newline for funsies
    inc rbx ;increase by 1 for the newline

    mov rax, syscallWrite ;write()
    mov rdi, 1 ;stdout
    mov rsi, buffer ;write the buffer
    mov rdx, rbx ;the full 21 bytes!
    syscall

    end:
        xor rdi, rdi ;0 for safe exit!
        mov rax, syscallExit ;exit() 
        syscall

;-------------------------------------------------------------------------------
