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
    ;;set up registers
    mov rcx, 22                 ;string length (kept track of)

    ;;check if the number's negative or zero and set a flag
    test rax, rax     ;sets CFLAGS for comparisons
    sets r8b          ;set r8b if it's negative
    jnz .notZero      ;if it's zero, quick return '0'
    dec rcx           ;string is now 1 long
    mov byte [rsi+rcx], '0'     ;puts '0' in the buffer in that position
    jmp .done                   ;and returns
.notZero:
    jns .loop                   ;if the number's not negative, skip this bit
    neg rax                     ;if it is, negate it first
.loop:
    xor rdx, rdx ;blank rdx (division)
    div r10 ;divide by 10 (decimal)
    add dl, '0' ;add 48 ('0') to the division modulo
    dec rcx ;"increase" length
    mov byte [rsi+rcx], dl ;store the character at buffer+length
    test rax, rax ;checks if the division result is 0, if it is we're done
    jnz .loop ;if it isn't repeat
.done:
    test r8b, r8b ;checks if the number was negative
    jz .positive
    dec rcx ;"increase" the length
    mov byte [rsi+rcx], '-' ;store the negative sign into the buffer
.positive:

                                ;add null terminator
    dec rcx
    mov byte [rsi+rcx], 0

                                ;set up the outpointer with the start of the string
    lea rax, [rsi+rcx]
    mov qword [rdi], rax

                                ;set the length of the string as the output (19-counter)
    mov rax, 21
    sub rax, rcx

    ret

;===============================================================================
