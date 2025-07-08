global main

section .text

; int a(int b)
a:
    push rbp                ; function prologue
    mov rbp, rsp
    mov rax, rdi            ; return b in rax
    pop rbp
    ret

; int main()
main:
    push rbp                ; function prologue
    mov rbp, rsp

    mov rdi, 5              ; pass 5 as the first argument to a()
    call a                  ; call a(5)
    
    sub rsp, 4              ; allocate 4 bytes for int c
    mov DWORD [rbp - 4], eax ; store returned value into c

    mov eax, 0              ; return 0 from main
    leave                   ; mov rsp, rbp; pop rbp
    ret