global _start ;required for the linker to see it

section .data ;variables
msg db "Hello world",10 ;hello! :3
len equ $ - msg ;has to be done directly after to get $ to work
msg2 db "HIIIII", 10 ;a second string
len2 equ $ - msg2 ;the length of the second variable
newline db 10 ;newline for just going "print(1, "\n", 1)"

section .text
_start:
    mov rax, 1 ;1 is the syscall for write(), needs to be in the accumulator for some reason
    mov rdi, 1 ;destination index register, in this case it's 1 because that's stdout
    mov rsi, msg ;source, the actual message to write
    mov rdx, len ;the length of the string passed in the data register, no clue how it should handle multiple vars
    syscall ;execute the syscall! black magic probably

    mov rax, 1 ;apparently still needed because rax gets destroyed (along with rcx and r11, they store the syscall return; the return instruction pointer; and the cflags, respectively)
    mov rsi, newline
    mov rdx, 1
    syscall ;i'm pretty sure the registers aren't cleared so i hope this just sends \n and not a kernel panic

    mov rax, 1
    mov rsi, msg2
    mov rdx, len2
    syscall ;i HOPE

    mov rax, 60 ;this is for exit() to shutdown the program cleanly
    xor rdi, rdi ;set rdi to 0 in a cool way because i'm cool, that's the destination for some reason
    syscall ;send exit(0)
