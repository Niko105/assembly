BITS 64
default rel ;use RIP relative addressing for compatibility, doesn't change code size
global _start ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated
;any extern functions come after this line
extern atoi ;int atoi(rdi=&string, rsi=len), clobbers rax
extern strlen ;int strlen(rdi=&string), no clobber
extern itoa ;int itoa(rdi=int, rsi=&buffer, rdx=&out_start). clobbers rax, rcx, r8, r9, r10

;===============================================================================

;-----------------------------------macros--------------------------------------
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

;---------------------------------syscalls equ----------------------------------
syscallRead     equ 0           ;rax=0, rdi=where from (0 for stdin), rsi=where to, rdx=size
syscallOpen     equ 2           ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=permissions if creating (mode) (0o755 or 0o644)
syscallWrite    equ 1           ;rax=1, rdi=where to (1 for stdout, 2 for stderr), rsi=message, rdx=length
syscallClose    equ 3           ;rax=3, rdi=fd
syscallExit     equ 60          ;rax=60, rdi=exit code
syscallExecve   equ 59          ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap     equ 9           ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap   equ 11          ;rax=11, rdi=address, rsi=size
syscallMkdir    equ 83          ;rax=83, rdi=directory name, rsi=permissions (mode)
syscallUnlink   equ 87          ;(rm), rax=87, rdi=filename
syscallRmdir    equ 84          ;rax=84, rdi=dir name
syscallLseek    equ 8           ;rax=8, rdi=fd, rsi=offset to seek, rdx=whence (0 (from beginning of the file), 1 (from current position), 2 (from end of the file))
syscallFork     equ 57          ;rax=57, that's it, returns 0 if we're the parent and the pid if we're the fork
syscallWait4    equ 61          ;rax=59, rdi=pid -1 any 0 any in same group >0 specific pid, rsi=int* to write exit code to, rdx=options (use 0), r10=rusage* usage struct pointer
;-------------------------------------------------------------------------------

;===============================================================================

section .data ;user data

    url     db "https://example.com", 0
    flag    db "-o",0
    curl    db "/usr/bin/curl",0
    outpath db "test.html",0
    stfu    db "-s",0

argv:                           ;make a struct in the data section, could've been just a long string but this is PROPERRRR
    dq curl
    dq stfu
    dq flag
    dq outpath
    dq url
    dq 0

;===============================================================================

section .bss ;unallocated data

;;; buffer resb 64              ;reserve buffer

;===============================================================================

section .text align=16 ;code, aligned on a 16byte boundary

;----------------------------------explanation----------------------------------
;uses fork and execv to open a new program and run stuff, in this case using
;curl to download a sample file on the disk, i could implement http myself
;using socket and connect but honestly i'd rather not
;-------------------------------------------------------------------------------

_start:
    mov rax, syscallFork        ;57
    syscall                     ;fork()
    test rax, rax               ;are we the child?
    jz child                    ;we sure are

    mov rdi, rax                ;wait for child
    mov rax, syscallWait4       ;rax=59, rdi=pid -1 any 0 any in same group >0 specific pid, rsi=int* to write exit code to, rdx=options (use 0), r10=rusage* usage struct pointer
    xor esi, esi                ;don't care
    xor edx, edx                ;don't care
    xor r10d, r10d              ;don't care
    syscall                     ;wait(pid), resumes once the child returns
    jmp exit                    ;and we're done
child:
    mov rax, syscallExecve      ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
    mov rdi, curl               ;program name
    mov rsi, argv               ;argument array
    xor edx, edx                ;inherit environment
    syscall                     ;open curl!
exit:
    mov rax, syscallExit        ;exit()
    xor edi, edi                ;that's the part that actually does the 0 code
    syscall                     ;terminate the program

;===============================================================================
