default rel
global atoi ;exported, extern itoa

;-------------------------------------------------------------------------------

section .text ;code
;atoi, ascii to integer, takes a string, the length of it, and returns the parsed byte in rax
;so how it works is....

;===============================================================================
;it holds the pointer to the string in rdi, and the current position being parsed in rcx as an offset
;it's got the length of the string inside of rsi, so it knows when to stop
;it reads the first byte, if it's '-' it's a negative number, so it sets rbx to 1 as a flag, and increases rdi
;it keeps looping over the string until rcx==rsi, increasing rcx every loop
;the string is processed as rax=rax*10+([rdi+rcx]-'0'), this works because it shifts rax by 10 and calculates the digit number, rdx is used for calculations
;at the end, if the negative flag is set (that would be rbx) and if it is it negates rax
;===============================================================================

atoi: ;int atoi(rdi=&string, rsi=len), clobbers rcx
    xor rcx, rcx ;blank offset
    xor rax, rax ;blank rax
    cmp byte [rdi], '-'
    sete r8b ;if the first byte is '-', r8's first bit gets set to 1, as a flag
    jne .loop ;if the number's positive, just parse it
        inc rdi ;increases the start of the string to the actual number
        dec rsi ;and decrease the size of the number
    .loop:
        movzx rdx, byte [rdi+rcx] ;load the current char
        sub rdx, '0' ;un-ascii it ([rdi+rcx]-'0')
        lea rax, [rax + rax*4] ;rax*10
        add rax, rax ;rax*10 part 2
        add rax, rdx ;rax=rax*10+([rdi+rcx]-'0')
        inc rcx ;next one then
        cmp rsi, rcx ;are we done yet? are we done yet? are we done yet? are we done yet? are we done yet? (rsi<rcx)
        jne .loop ;not yet
    test r8b, r8b ;is the flag set?
    jz .positive ;not set, so it's positive!
        neg rax ;negative number
    .positive:
    ret ;return to caller

;-------------------------------------------------------------------------------
