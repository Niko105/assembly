global _start ;entry point 

;-------------------------------------------------------------------------------

section .data ;variables
;syscalls equ
syscallOpen  equ 2
syscallWrite equ 1
syscallClose equ 3
syscallExit  equ 60

;ppm header
header db "P6",10,"255 255",10,"255",10 ;P6\nWIDTH HEIGHT\n255\n, ppm image header
headerLen equ $ - header ;take position of the last thing and subtract header, bam, length
width equ 255 ;#define width n
height equ 255 ;#define height n

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
pixel resd 1 ;ppm pixel variable, 4 bytes, minimum space for 3 bytes (for rgb)

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
    sub rsp, 16 ;make space for TWO variables on the stack (2 64bit variables, 16 bytes), using the stack to avoid register clobbering
    mov qword [rsp], height ;set the first counter, gotta specify qword for [] stuff
    externalLoop:
        mov qword [rsp+8], width ;set the second counter (after 8 bytes there's the second one!)
        internalLoop:
            ;setting up the pixels for a debug texture
            xor rax, rax ;blank rax
            add rax, [rsp] ;i
            shl rax, 8 ;shift them to the next colour channel
            add rax, [rsp+8] ;+j
            mov dword [pixel], eax ;0x00000000BBGGRR, load the pixel with the value, eax since it's 32bit
            mov dword [pixel+2], 0x00 ;load the max blue value in the blue channel (3rd byte)

            ;syscall time!
            mov rax, syscallWrite; write()
            mov rdi, [fd] ;the file descriptor as output (zero extended automatically)
            mov rsi, pixel
            mov rdx, 3 ;move the 3 bytes of the pixel (BB GG RR)
            syscall ;write!

            ;inner counter decrease
            mov rax, [rsp+8] ;offload for faster operations
            dec rax ;decrease the counter
            mov [rsp+8], rax ;and load again!
            jnz internalLoop ;if it's not 0, loop
    
        ;outer counter decrease
        mov rax, [rsp] ;offload for faster operations
        dec rax ;decrease the counter
        mov [rsp], rax ;and load again!
        jnz externalLoop ;if it's not 0, loop!
    add rsp, 16 ;clear the space i gave for i and j

    ;syscall to close the file to be proper
    mov rax, syscallClose ;close()
    mov rdi, [fd] ;the file
    syscall ;NOW

    end:
        mov rax, syscallExit ;exit()
        xor rdi, rdi
        syscall

;-------------------------------------------------------------------------------
