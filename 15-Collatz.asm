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

inout resb 24                   ;reserve 24 bytes for input/output
out_start resq 1                ;reserve one singular 64 bit buffer for the itoa output

;===============================================================================

section .text align=16 ;code, aligned on a 16byte boundary

;----------------------------------explanation----------------------------------
;calculates the nth collatz sequence and outputs how long it took to execute it
;takes input from stdin and outputs in stdout, real number using my
;implementation of atoi and itoa, standalone program so hehehehehehe
;-------------------------------------------------------------------------------

_start:
    ;; take input from stdin
    xor eax, eax                ;set rax to 0 (syscall read)
    xor edi, edi                ;set rdi to 0 (stdin)
    mov rsi, inout              ;place into buffer
    mov rdx, 24                 ;read 24 bytes (64 bit numbers are at most 20 digits, plus -)
    syscall                     ;read(stdin); now inout has the string and rax has the length read

    ;; transform the string to a number
    dec rax                     ;decrease the string length to exclude '\n'
    mov rsi, rax                ;save the string length to the second atoi input
    mov rdi, inout              ;move the string pointer to the first input
    call atoi                   ;now rax should have the number, and rcx, r8, r10 are clobbered

    ;; loop setup, rcx for counting iterations, rax for the number itself to be stored in
    xor ecx, ecx                ;blank ecx for the iteration count
    ;; main collatz loop
.loop:
    cmp rax, 1                  ;are we done yet? (did we reach 1?)
    je .end                     ;lookies! we're done! (or not)
    test rax, 1                 ;check if the number's even (zero flag set) or odd (zero flag not set)
    jz .even                    ;if even, jump to the even branch, otherwise continue to odd branch
.odd:                           ;this label is useless actually, but the compiled code removes it, it's for readability
    lea rax, [rax+rax*2]        ;rax*3 (using lea's barrel shifter)
    inc rax                     ;+1
    jmp .next                   ;unconditional jump to .next to avoid the even branch
.even:
    shr rax, 1                  ;shift right by one for /2, could use tzcnt for multiple /2 in one go but then i'd desync the rcx
.next:
    inc rcx                     ;add one to the iteration count
    jmp .loop                   ;loop back to the start of the loop
.end:

    ;; transform the number back to a string
    mov rsi, inout              ;setup the buffer for itoa
    mov rdi, rcx                ;send the number to convert
    mov rdx, out_start          ;send the outpointer for the buffer's new start location
    call itoa                   ;rax now has the length of the number as a string, and inout has the number string itself (right to left), with out_start having its start location

    ;; write to stdout
    mov rdx, rax                ;load the number of bytes to write
    mov rax, syscallWrite       ;so like turns out you need to set up the rax register for syscall who could've thought.
    mov rdi, 1                  ;stdout
    mov rsi, [out_start]        ;it's gotta be funky cause the inout buffer is useless to me now
    syscall                     ;write(stdout); now rax has the output code and hopefully my terminal has the result

exit:
    mov rax, syscallExit        ;exit()
    xor edi, edi                ;that's the part that actually does the 0 code
    syscall                     ;terminate the program

;===============================================================================
