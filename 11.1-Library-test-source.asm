global stringLength ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated

;yay! this will need to be linked separately with ld program.o 11.1-Library-test-source.o -o program

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


;-------------------------------------------------------------------------------

section .bss ;unallocated data


;-------------------------------------------------------------------------------

section .text ;code
;int strlen(&string);
stringLength: ;get how long a null terminated string is. rsi=address(in), rax=length(out)
    ;pre/post function stack isn't needed
    xor rax, rax ;set rax to 0
.loop:
    mov bl, byte [rsi + rax] ;check one byte at rsi (+rax as offset)
    cmp bl, 0 ;is the byte 0?
    je .done ;check if it's equal
    inc rax ;it's not, f*ck, increase rax since we gotta check a new byte
    jmp .loop ;and loop
.done: ;it is, f*ck
    ret ;return to caller

;-------------------------------------------------------------------------------
