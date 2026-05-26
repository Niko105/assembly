BITS 64
default rel
global itoa ;exported, extern itoa to use it elsewhere

;===============================================================================

section .text align=16

;----------------------------------explanation----------------------------------
;itoa, integer to ascii, takes an integer, a buffer, and an out-pointer 
;and returns the length of the string and the pointer to the start of it inside the out-pointer, null terminated
;the buffer size is assumed to be sufficient, for safe usage a minimum of 20 bytes be used, as that is enough to hold at least 22 characters (22 quad words)
;for the 64 bit limit (20 chars), a negative sign (1 char) and the null terminator (1 char)
;unsafe, probably has some issues, but fast, and that's what i care about :3
;-------------------------------------------------------------------------------

;int itoa(rdi=int, rsi=&buffer, rdx=&out_start). clobbers rax, rcx, r8, r10
itoa:
    mov r11, 22                 ;string length (kept track of)
    mov r9, rdx                 ;saving the outpointer from the mul wrath
    mov rax, rdi                ;saving the int for the mul wrath
    test rax, rax               ;checks the number (set CFLAGS)
    sets r8b                    ;set r8b if it's negative (set sign)
    jnz .notZero                ;if it's zero, quick return '0'
    dec r11                     ;string is now 1 long
    mov byte [rsi+r11], '0'     ;puts '0' in the buffer in that position
    jmp .done                   ;and returns
.notZero:
    jns .loop                   ;if the number's not negative, skip this bit
    neg rax                     ;if it is, negate it first
.loop:
    mov rcx, 0xCCCCCCCCCCCCCCCD ;magic number for division (cause div is slowww)
    mov r10, rax                ;save the dividend
    mul rcx                     ;rdx:rax = rax*(magic)
    shr rdx, 3                  ;rdx = rax/10
    lea rcx, [rdx+rdx*4]        ;quot*5
    add rcx, rcx                ;*2 (*10)
    sub r10, rcx                ;aand get the remainder!
    add r10b, '0'               ;add 48 ('0') to the division modulo
    dec r11                     ;string length +1
    mov byte [rsi+r11], r10b    ;store the character at buffer+length
    mov rax, rdx                ;set up quotient for next div
    test rax, rax               ;checks if the division result is 0, if it is we're done
    jnz .loop                   ;if it isn't repeat
.done:
    test r8b, r8b               ;checks if the number was negative
    jz .positive
    dec r11                     ;guess
    mov byte [rsi+r11], '-'     ;store the negative sign into the buffer at the end
.positive:
    dec r11                     ;increase string length
    mov byte [rsi+r11], 0       ;add the null terminator (\00)
    lea rax, [rsi+r11]          ;get the start of the string set
    mov qword [r9], rax         ;and put it in the outpointer
    mov rax, 22                 ;ready up for the length calculation
    sub rax, r11                ;and calculate r11-22 for the length
    ret                         ;return to caller

;===============================================================================
