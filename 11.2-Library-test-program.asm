global _start ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated
extern stringLength

;-------------------------------------------------------------------------------

section .data ;variables
;syscalls equ
syscallRead  equ 0 ;rax=0, rdi=where from, rsi=where to, rdx=size
syscallOpen  equ 2 ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=mode
syscallWrite equ 1 ;rax=1, rdi=where from, rsi=message, rdx=length
syscallClose equ 3 ;rax=3, rdi=fd
syscallExit  equ 60 ;rax=60, rdi=exit code
syscallExec  equ 59 ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap  equ 9 ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap equ 11 ;rax=11, rdi=address, rsi=size

;string
string db "hello",0

;-------------------------------------------------------------------------------

section .bss ;unallocated data


;-------------------------------------------------------------------------------

section .text ;code
_start:
    mov rsi, string
    call stringLength
    mov rdx, rax

    mov rax, syscallWrite ;write()
    mov rdi, 1 ;stdout
    mov rsi, rsi ;write the string
    mov rdx, rdx ;string ;length
    syscall

    end:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;-------------------------------------------------------------------------------
