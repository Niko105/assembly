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
syscallFork     equ 57          ;rax=57, that's it, returns the child's pid if we're the parent, 0 if we're the child
syscallWait4    equ 61          ;rax=59, rdi=pid -1 any 0 any in same group >0 specific pid, rsi=int* to write exit code to, rdx=options (use 0), r10=rusage* usage struct pointer
syscallClone    equ 56          ;rax=56, rdi=flags (use 0x310F00 and look up as needed), rsi=rsp (top of the shared memory stack), rdx=parent tid*, r10=child tid*, r8=tls pointer, returns 0 if we're the thread and tid if we're the parent
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
;since i really have no idea what to use the threads for, i'll just explain
;them here instead of writing any code. i can use threads for parallel things
;and they work in a similar way to forks, just using clone instead of it
;they operate on a shared memory that must be preallocated using mmap to get a
;chunk on the heap, then you pass a pointer to the top of it like a stack, the
;mmap must be MAP_PRIVATE|MAP_ANONYMOUS which has hex 0x22, with an fd of -1
;since it's not using a file, it has to get the base+size since the stack
;grows downwards. once it's set rsp points to that place and is used like a
;normal stack, and it's the only not shared area, everything else (.data, .bss)
;is shared across them.
;mov rax, 9          ;mmap
;xor edi, edi        ;no requested address
;mov rsi, 8192       ;8kb stack
;mov rdx, 3          ;PROT_READ|PROT_WRITE
;mov r10, 0x22       ;MAP_PRIVATE|MAP_ANONYMOUS
;mov r8, -1          ;no fd
;xor r9d, r9d        ;no offset
;syscall             ;returns base address in rax
;this just gives me the mmap needed for the thread itself, then i need to
;;mov rax, 56
;mov rdi, 0x310F00
;mov rsi, [thread_stack_top]
;lea rdx, [parent_tid]
;lea r10, [child_tid]
;xor r8d, r8d
;syscall
;where child/parent_tid are memory locations in .bss for the syscall to write
;these addresses to, you know, for having them, then you can call futex uses to
;join the threads to the main program after (it's another syscall). mmap has to
;be called every single time you wanna make a new thread btw.
;you see why threads are so expensive to create now?
;-------------------------------------------------------------------------------

_start:

exit:
    mov rax, syscallExit        ;exit()
    xor edi, edi                ;that's the part that actually does the 0 code
    syscall                     ;terminate the program

;===============================================================================
