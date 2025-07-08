global _start ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated

extern itoa ;int itoa(rdi=num, rsi=buffer, rdx=size, rcx=pointer to string start buffer(1q))

;-------------------------------------------------------------------------------

section .data ;variables
;syscalls equ
syscallRead  equ 0 ;rax=0, rdi=where from, rsi=where to, rdx=size
syscallOpen  equ 2 ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=permissions (mode) (0o755 or 0o644)
syscallWrite equ 1 ;rax=1, rdi=where from, rsi=message, rdx=length
syscallClose equ 3 ;rax=3, rdi=fd
syscallExit  equ 60 ;rax=60, rdi=exit code
syscallExec  equ 59 ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap  equ 9 ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap equ 11 ;rax=11, rdi=address, rsi=size
syscallMkdir equ 83 ;rax=83, rdi=directory name, rsi=permissions (mode)


;-------------------------------------------------------------------------------

section .bss ;unallocated data
buffer resb 30 ;buffer for itoa
strStart resq 1 ;pointer to start of string

;-------------------------------------------------------------------------------

section .text ;code
_start:
    mov rdi, -2322
    mov rsi, buffer
    mov rdx, 30
    mov rcx, strStart
    call itoa
    mov rdx, rax

    mov rax, syscallWrite
    mov rdi, 1
    mov rsi, [strStart]
    mov rdx, rdx
    syscall

    end:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;-------------------------------------------------------------------------------
