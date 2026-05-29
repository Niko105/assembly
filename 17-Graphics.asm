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
syscallExec     equ 59          ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap     equ 9           ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap   equ 11          ;rax=11, rdi=address, rsi=size
syscallMkdir    equ 83          ;rax=83, rdi=directory name, rsi=permissions (mode)
syscallUnlink   equ 87          ;(rm), rax=87, rdi=filename
syscallRmdir    equ 84          ;rax=84, rdi=dir name
syscallLseek    equ 8           ;rax=8, rdi=fd, rsi=offset to seek, rdx=whence (0 (from beginning of the file), 1 (from current position), 2 (from end of the file))
;-------------------------------------------------------------------------------

;----------------------------------open flags----------------------------------

;-------------------------------------------------------------------------------

;===============================================================================

section .data ;user data

    framebufferPath db "/dev/fb0",0
    errorNmapMess   db "Error with nmap",10,0    ;18 to write
    errorOpenMess   db "Error opening file",10,0 ;21 to write

;===============================================================================

section .bss ;unallocated data

;;; buffer resb 64              ;reserve buffer

;===============================================================================

section .text align=16 ;code, aligned on a 16byte boundary

;----------------------------------explanation----------------------------------
;opens the framebuffer and attempts to do anything with it
;-------------------------------------------------------------------------------

_start:
    ;; get /dev/fb0 open
    mov rax, syscallOpen        ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=permissions if creating (mode) (0o755 or 0o644)
    mov rdi, framebufferPath    ;path of the file
    mov rsi, 2                  ;O_RDWR, read/write
    xor edx, edx                ;not creating a file, useless to set
    syscall                     ;open("/dev/fb0")
    test rax, rax               ;did we error out?
    js errorOpen                ;FUUUU
    mov r14, rax                ;save fd
    ;; map memory to write to
    mov rax, syscallMmap        ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
    xor edi, edi                ;no need for custom position
    mov rsi, 8294400            ;1920*1080*4, HD screen and 4 bytes per pixel
    mov rdx, 3                  ;PROT_READ|PROT_WRITE
    mov r10, 1                  ;MAP_SHARED
    mov r8, r14                 ;file descriptor
    mov r9, 0                   ;offset
    syscall                     ;nmap()
    test rax, rax               ;did we error out?
    js errorNmap                ;FUUUUUUUUUUUU
    mov r15, rax                ;save the buffer position
    ;; write to it, offset=(y*1920+x)*4
    mov DWORD [r15+4149120], 0x00FF0000 ;red pixel 0x00RRGGBB
    mov DWORD [r15+4149124], 0x0000FF00 ;green pixel
    mov DWORD [r15+4149128], 0x000000FF ;blue
    mov DWORD [r15+4149132], 0x00FFFF00 ;yellow
    mov DWORD [r15+4149136], 0x00FF00FF ;ourple

    ;; sleep for 2 seconds
    sub rsp, 16                 ;make space on the stack for the crappy struct it needs
    mov QWORD [rsp], 2          ;seconds
    mov QWORD [rsp+8], 0        ;nanoseconds
    mov rax, 35                 ;nanosleep syscall
    lea rdi, [rsp]              ;give it the struct
    xor esi, esi                ;struct to write to if it gets interrupted (it gives you how much time is left) (idc)
    syscall                     ;nanosleep()
    add rsp, 16                 ;free stack

exit:
    mov rax, syscallExit        ;exit()
    xor edi, edi                ;that's the part that actually does the 0 code
    syscall                     ;terminate the program

errorNmap:
    mov rax, syscallWrite       ;rax=1, rdi=where to (1 for stdout, 2 for stderr), rsi=message, rdx=length
    mov rdi, 2                  ;stderr
    mov rsi, errorNmapMess      ;Error with nmap
    mov rdx, 18                 ;18 bytes
    syscall                     ;write(stdin, "Error with nmap\n")
    mov rax, syscallExit        ;exiting with error
    mov rdi, 2                  ;error code 2
    syscall                     ;exit(1)

errorOpen:
    mov rax, syscallWrite       ;rax=1, rdi=where to (1 for stdout, 2 for stderr), rsi=message, rdx=length
    mov rdi, 2                  ;stderr
    mov rsi, errorOpenMess      ;Error opening file
    mov rdx, 20                 ;21 bytes
    syscall                     ;write(stdin, "Error opening file\n")
    mov rax, syscallExit        ;exiting with error
    mov rdi, 1                  ;error code 1
    syscall                     ;exit(1)

;===============================================================================
