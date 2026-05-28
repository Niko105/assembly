global _start ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated

;-------------------------------------------------------------------------------

section .data ;variables
;syscalls equ
syscallRead   equ 0 ;rax=0, rdi=where from, rsi=where to, rdx=size
syscallOpen   equ 2 ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=permissions (mode) (0o755 or 0o644)
syscallWrite  equ 1 ;rax=1, rdi=where from, rsi=message, rdx=length
syscallClose  equ 3 ;rax=3, rdi=fd
syscallExit   equ 60 ;rax=60, rdi=exit code
syscallExec   equ 59 ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap   equ 9 ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap equ 11 ;rax=11, rdi=address, rsi=size
syscallMkdir  equ 83 ;rax=83, rdi=directory name, rsi=permissions (mode)
syscallUnink  equ 87 ;(rm), rax=87, rdi=filename
syscallRmdir  equ 84 ;rax=84, rdi=dir name

;ppm header
header db "P6",10,"4096 4096",10,"255",10 ;P6\nWIDTH HEIGHT\n255\n, ppm image header
headerLen equ $ - header ;take position of the last thing and subtract header, bam, length
width equ 4096 ;#define width n
height equ 4096 ;#define height n

;syscall(open) settings
file_name db "./test.ppm", 0 ;filename of ppm image that's about to be created, null terminated
O_WRONLY equ 1
O_CREAT  equ 64
O_TRUNC  equ 512
openflags equ O_WRONLY | O_CREAT | O_TRUNC ;0x241
openmode equ 0o644 ;permissions, rw-r--r--

;-------------------------------------------------------------------------------

section .bss ;unallocated data
fd resd 1 ;reserve a 16 bit space for the file descriptor
imageBuffer resd width*height*3 ;buffer for the image

;-------------------------------------------------------------------------------

section .text ;code
_start:
    ;make a new file and open it, get the file descriptor and store it in ram
    mov rax, syscallOpen ;syscall 2 is open, using equ for readability
    mov rdi, file_name
    mov rsi, openflags
    mov rdx, openmode
    syscall ;this opens the file and puts the file descriptor (handle) to rax (return register for syscall)

    mov [fd], eax ;store the file descriptor (:tada:)

    ;print the header to it
    mov rax, syscallWrite; write()
    mov edi, [fd] ;the file descriptor as output
    mov rsi, header
    mov rdx, headerLen
    syscall ;write!

    ;loop over the image to store the gradient
    sub rsp, 24 ;3 variables (8+8+8)
    mov qword [rsp], 0x0 ;set the first counter, gotta specify qword for [] stuff
    mov rbx, imageBuffer ;pointer to the current location of the image
    xor r8, r8 ;blank r8
    externalLoop:
        mov qword [rsp+8], 0x0 ;set the second counter (after 8 bytes there's the second one!)
        ;set [rsp+16] to r8*16 for the new line
        imul rax, r8, 16
        mov qword [rsp+16], rax
        internalLoop:
            ;making the rgb pixel
            mov dl, [rsp] ;load i
            mov byte [rbx], dl ;red, i-slaved

            mov dl, [rsp+8] ;load j
            mov [rbx+1], dl ;green j-slaved

            mov dl, [rsp+16] ;load BLUE
            mov [rbx+2], dl ;BLUE

            add rbx, 3 ;next pixel!

            ;inner counter increase
            inc qword [rsp+8] ;decrease the counter
            cmp byte [rsp+8], 255 ;check if we're done with this line
            jne notYet0
                inc qword [rsp+16]
            notYet0:
            cmp qword [rsp+8], width ;check if we reached the width target
            jne internalLoop ;if it's not at the target, loop
        
        ;outer counter increase
        inc qword [rsp] ;decrease the counter
        cmp byte [rsp], 255 ;check if we're done with this square
        jne notYet1
            inc r8
        notYet1:
        cmp qword [rsp], height ;check if we reached the height target
        jne externalLoop ;if it's not at the target, loop!
    add rsp, 16 ;clear the space i gave for i and j

    ;syscall time!
    mov rax, syscallWrite
    mov rdi, [fd]
    mov rsi, imageBuffer
    mov rdx, width*height*3
    syscall

    ;syscall to close the file to be proper
    mov rax, syscallClose
    mov rdi, [fd]
    syscall

    end:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;-------------------------------------------------------------------------------
