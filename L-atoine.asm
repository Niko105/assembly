default rel
global atoine ;exported, extern atoine

;-------------------------------------------------------------------------------

section .text ;code

;===============================================================================
;atoine, ascii to integer null ending
;the pointer to the start of the string's buffer is held in the rdi register
;the first byte is checked at the start outside of the loop for a negative sign
;if it is found, r8b is set as a flag and the pointer is moved to the start of the number
;inside of the loop the string is checked byte for byte and processed into rax
;rax is updated following the following formula: rax=rax*10+([rdi+rcx]-'0')
;this parses the ascii digit into its integer value and accumulates it
;the multiplication by ten is using a lea micro-optimization
;after rax has been updated, increase rcx by one
;---
;in this code, rax is the result, rdi is the string pointer, and rcx is the counter for the current string position
;r8b is used as a negative flag, and rdx is used as a temporary buffer for calculations
;---
;this code has no input validation and doesn't use lea micro-optimizations, do not use in critical code
;cosider using satoine for safe operations
;===============================================================================

atoine: ;int atoine(rdi=&string), clobbers rdx
    xor rcx, rcx ;blank offset
    xor rax, rax ;blank rax
    cmp byte [rdi], '-'
    sete r8b ;if the first byte is '-', r8's first bit gets set to 1, as a flag
    jne .loop ;if the number's positive, just parse it
        inc rdi ;increases the start of the string to the actual number
    .loop:
        movzx rdx, byte [rdi+rcx] ;load the current char
        cmp rdx, 0 ;are we done yet? are we done yet? are we done yet? are we done yet? are we done yet? (checks if the current byte is a null char)
        je .done ;we are!
        sub rdx, '0' ;un-ascii it ([rdi+rcx]-'0')
        lea rax, [rax + rax*4] ;multiply
        add rax, rax ;multiply part two
        add rax, rdx ;rax=rax*10+([rdi+rcx]-'0')
        inc rcx ;next one then
        jmp .loop ;since the loop ending check is above, jump manually
    .done:
    test r8b, r8b ;is the flag set?
    jz .positive ;not set, so it's positive!
        neg rax ;negative number
    .positive:
    ret ;return to caller

;-------------------------------------------------------------------------------
