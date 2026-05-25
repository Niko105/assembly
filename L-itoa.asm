BITS 64
default rel
global itoa ;exported, extern itoa

;===============================================================================

section .text align=16

;----------------------------------explanation----------------------------------
;itoa, integer to ascii, takes an integer, a buffer, and an out-pointer 
;and returns the length of the string and the pointer to the start of it inside the out-pointer, null terminated
;the buffer size is assumed to be sufficient, for safe usage a minimum of 20 bytes be used, as that is enough to hold the negative 64 bit limit + null terminator
;[futher explanation of steps]
;[more steps explanations]
;
;despite the arguments being those above, rdx and rax are used in div, and as such rdx is re-assigned to rdi and rdi is moved to rax
;then
;rax is the number to translate
;rdi is now the outpointer
;rsi is the pointer to the start of the buffer
;rcx is the length of the string
;r8b is used as a negative flag
;r10 is used as a constant for division (10)
;
;this code does no input validation, this function's considered unsafe, only use following documentation
;-------------------------------------------------------------------------------

;int itoa(rdi=int, rsi=&buffer, rdx=&out_start). clobbers rax, rcx, r8, r10
itoa:
    ;swap some stuff around for division and such, which is very slow, do consider updating this function or at least marking it as slow in the documentation
    mov rax, rdi
    mov rdi, rdx

    ;set up registers
    mov rcx, 21 ;length+1
    mov r10, 10 ;constant

    ;check if the number's negative or zero and set a flag
    test rax, rax ;set cflags
    sets r8b ;set r8b if it's negative
    jnz .notZero ;if it's zero adds 0, sets up length and such, and returns
        dec rcx
        mov byte [rsi+rcx], '0'
        jmp .done
    .notZero:
    jns .loop ;if the number is negative it'll break everything, so negate it
        neg rax
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
        dec rax ;remove null terminator
        
    ret

;===============================================================================
