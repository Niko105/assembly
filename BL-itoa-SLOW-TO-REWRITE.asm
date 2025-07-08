default rel
global itoaS ;exported, extern itoa

;-------------------------------------------------------------------------------

section .text ;code
;int itoa(rdi=num, rsi=buffer, rdx=size, rcx=pointer to string start buffer(1q)), clobbers several registers. the string start buffer has to be dereferenced to be used
;rax=number to modify
;rsi=pointer to buffer
;rdi=buffer size
;rcx=pointer to end of the buffer
;rbx=divisor
;r8=string start pointer
;returns with rax as the length
itoaS:
    push rbx ;save rbx, no stack frame needed
    mov rax, rdi ;move the number to modify into a useful register
    mov r9, rdi ;also save it to r9 for later referencing
    mov rdi, rdx ;save the size of the buffer
    mov r8, rcx ;save the start of the pointer buffer (1q)
    mov rcx, rsi ;setup rcx as the start of the buffer
    add rcx, rdi ;add the size of it to get to the end+1
    test rax, rax ;test if the number=0
    jne .notZero ;if by any chance the number isn't 0, actually run the conversion loop, but if it is, run a very small piece adding '0'
        dec rcx ;move back one spot in the buffer
        mov byte [rcx], '0' ;store 0 into the buffer
        jmp .done ;and yeah we're done! continue on with calculating the ending returns
    .notZero:
    test rax, rax ;toggle sign flag if it's negative
    jns .positive0
        neg rax ;if it's negative, change that, 
    .positive0:
        mov rbx, 10 ;set up rbx for divisions, just because we need a place to store 10
    .loop:
        xor rdx, rdx ;set rdx to 0 since div uses rdx:rax
        div rbx ;rax=rax/10, rdx=rax%10 - since rdx is null
        add dl, '0' ;add 48 ascii to the lower 8 bytes of rdx (the modulo) to transform the char (8b) to ascii (by adding 48)
        dec rcx ;move back one spot in the buffer
        mov [rcx], dl ;store the one byte (char) into the buffer
        test rax, rax ;test if rax/rbx is 0 yet
        jnz .loop ;if it's not 0, head back to the start
    .done:
        test r9, r9 ;toggle sign flag if it's negative, done now after we're done writing because it's backwards >.<
        jns .positive1
            dec rcx ;move back one spot in the buffer
            mov byte [rcx], '-' ;store the negative sign into the buffer
        .positive1:
        ;remember the comment at the start saying what does what? yeah fuck that
        ;this is kind of fucked, so here's what it does
        ;rbx gets set to be the ending position of the buffer, same as rdx
        ;rbx then becomes (buffer+buffer_size)-current_buffer_position with the current position being rcx, since rcx decreased every time we wrote a byte this operation gives us the total length of the string
        mov rbx, rsi ;set up rbx as the start of the buffer
        add rbx, rdi ;go to the end+1
        sub rbx, rcx ;subtract how many bytes we've written to get the total length of the string
        mov rax, rbx ;set up rax for returning
        mov qword [r8], rcx ;and move the starti of the string to r8's buffer for the user's convenience

    pop rbx ;restore rbx
    ret ;return to caller

;-------------------------------------------------------------------------------
