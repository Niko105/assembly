default rel
global strlen ;exported function, import with extern strlen

;-------------------------------------------------------------------------------

section .text ;code
;int strlen(rdi=&string), no clobber
strlen: ;gets how long a null terminated string is. rdi=address(in), rax=length(out)
    ;pre/post function stack isn't needed
    xor rax, rax ;set rax to 0
    .loop:
        cmp BYTE PTR [rdi+rax*1], 0 ;direct memory byte comparison, faster than bl
        je .done ;check if it's equal
        inc rax ;it's not, f*ck, increase rax since we gotta check a new byte
        jmp .loop ;and loop
    .done: ;it is, f*ck
        ret ;return to caller

;-------------------------------------------------------------------------------
