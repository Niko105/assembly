BITS 64
default rel ;use RIP relative addressing for compatibility, doesn't change code size
global _start ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated
;any extern functions come after this line


;===============================================================================

;-----------------------------------macroes-------------------------------------
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
;-------------------------------------------------------------------------------

;----------------------------------syscalls equ---------------------------------
syscallRead   equ 0 ;rax=0, rdi=where from (0 for stdin), rsi=where to, rdx=size
syscallOpen   equ 2 ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=permissions (mode) (0o755 or 0o644)
syscallWrite  equ 1 ;rax=1, rdi=where to (1 for stdout, 2 for stderr), rsi=message, rdx=length
syscallClose  equ 3 ;rax=3, rdi=fd
syscallExit   equ 60 ;rax=60, rdi=exit code
syscallExec   equ 59 ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap   equ 9 ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap equ 11 ;rax=11, rdi=address, rsi=size
syscallMkdir  equ 83 ;rax=83, rdi=directory name, rsi=permissions (mode)
syscallUnlink equ 87 ;(rm), rax=87, rdi=filename
syscallRmdir  equ 84 ;rax=84, rdi=dir name
syscallLseek  equ 8 ;rax=8, rdi=fd, rsi=offset to seek, rdx=whence (0 (from beginning of the file), 1 (from current position), 2 (from end of the file))
;-------------------------------------------------------------------------------

;===============================================================================

section .data ;user data

;string db "Hello world!",0

;===============================================================================

section .bss ;unallocated data

;buffer resb 50 ;reserve 50 bytes as a scratch buffer

;===============================================================================

section .text align=16 ;code, aligned on a 16byte boundary

;----------------------------------explanation----------------------------------
;code explanation
;-------------------------------------------------------------------------------

_start:
    

    _exit:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;===============================================================================
