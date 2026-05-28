BITS 64
default rel ;use RIP relative addressing for compatibility, doesn't change code size
global _start ;entry point, variables given ./program v are stored in argv argc and envp
;[rsp] has argc, [rsp+8] is not argv[0] but it is the pointer to it
;meaning [rsp+8+n*8] points at the nth argument given, every argument is null terminated
;any extern functions come after this line

;===============================================================================

;-----------------------------------macros--------------------------------------
;zeroing buffers nasm macro, takes 2 inputs (start of the buffer, size in bytes), clobbers rax, rdi, rcx
%macro blankBuffer 2
    mov rcx, %2
    xor rax, rax
    mov rdi, %1
    rep stosb
%endmacro

;zeroing 8 byte aligned buffers nasm macro, takes 2 inputs (start of the buffer, size in qwords), clobbers rax, rdi, rcx
%macro blank8Buffer 2
    mov rcx, %2
    xor rax, rax
    mov rdi, %1
    rep stosq
%endmacro
;-------------------------------------------------------------------------------

;---------------------------------syscalls equ----------------------------------
syscallRead   equ 0             ;rax=0, rdi=where from (0 for stdin), rsi=where to, rdx=size
syscallOpen   equ 2             ;rax=2 returns file descriptor, rdi=filename, rsi=flags, rdx=permissions (mode) (0o755 or 0o644)
syscallWrite  equ 1             ;rax=1, rdi=where to (1 for stdout, 2 for stderr), rsi=message, rdx=length
syscallClose  equ 3             ;rax=3, rdi=fd
syscallExit   equ 60            ;rax=60, rdi=exit code
syscallExec   equ 59            ;rax=59, rdi=program name (string, null term), rsi=arguments (string array, null term), rdx=env (string array, null term)
syscallMmap   equ 9             ;rax=9 returns block address, rdi=requested addr (use 0 for auto), rsi=size, rdx=protections, r10=flags, r8=fd (use -1 for no file), r9=offset (use 0)
syscallMunmap equ 11            ;rax=11, rdi=address, rsi=size
syscallMkdir  equ 83            ;rax=83, rdi=directory name, rsi=permissions (mode)
syscallUnlink equ 87            ;(rm), rax=87, rdi=filename
syscallRmdir  equ 84            ;rax=84, rdi=dir name
syscallLseek  equ 8             ;rax=8, rdi=fd, rsi=offset to seek, rdx=whence (0 (from beginning of the file), 1 (from current position), 2 (from end of the file))
;-------------------------------------------------------------------------------

;===============================================================================

section .data ;user data

;string db "Hello world!",0

;===============================================================================

section .bss ;unallocated data

buffer resq 64                   ;buffer allocation

;===============================================================================

section .text align=16 ;code, aligned on a 16byte boundary

;----------------------------------explanation----------------------------------
;this is an excercise file for trying out System-V ABI standards regarding
;structs, parameter passing, and calling conventions.
;as per ABI AMD64, rbx, rsp, rbp, and r12--r15 are preserved, the rest are
;considered scratch and can be overwritten by the callee as needed.
;return value is in rax, if it doesn't fit in rax the high bits are pushed to
;rdx, if that doesn't fit either then the caller must reserve space in a pointer
;passed in rdi, then the same pointer is returned in rax as normal (outpointer).
;parameters are passed in order in rdi, rsi, rdx, rcx, r8, and r9; if there are
;more arguments then the stack will be used in reverse order (push 3 2 1) and
;are not preserved, and the stack itself must be 16-byte aligned before a call.
;for structs, if it fits inside an 8-byte space then it is passed packed inside
;the normal argument register, in case it fits in 16 bytes then it will be
;packed inside rdi and rsi. in case the struct exceeds 16 bytes then it will be
;allocated on the stack and the register will hold a reference to its location.
;the stack grows downwards, a function will need to pre-allocate its space on
;the stack upon being called (if it requires any) by subtracting from the stack
;pointer (rsp), upon return it must balance its use by either restoring rsp or
;adding back the amount subtracted (the amount is in BYTES, be careful).
;on call, the return address is pushed to the stack, this misaligns it by
;8 bytes, and makes it so [rsp] points towards the return address, not the first
;stack argument. [rsp+8] will contain it.
;you can use lea reg, [rsp+offset] for saving the address of a certain struct
;or variable to a register if the data is on the stack, and use the normal
;pointer to save it otherwise.
;structs are packed low-to-high, masking and shifting is usually used for
;getting the singular values.
;for the conventions on callee-caller register conventions (like rbx), it is
;common to use push/pop, this misaligns the stack, be wary of it.
;struct packing must be aligned to their sizes, char a; int b; will require a
;3 byte pad after the char to keep the int's aligment, while the char can just
;be aligned to 1 byte.
;
;now, specifically, this exercise will focus on turning
;
;; typedef struct {
;;     int x;                       //x coordinate
;;     int y;                       //y coordinate
;; } Point;
;; typedef struct {
;;     Point origin;
;;     int width;                   //natural number, width of the rect
;;     int height;                  //natural number, height of the rect
;;     int colour;                  //number whose bytes are AARRGGBB
;; } Rect;
;; int area(Rect r);                //calculates the area of the rect
;; Point center(Rect r);            //calculates the center of rect
;; int contains(Rect r, Point p);   //calculates if the point is in the rect
;; //-----//
;; Point a = Point(4, 3);           //create a point
;; Rect  a = Rect(a, 4, 2, 0);      //create a rect
;; Point b = Point(2, 3);           //create another point
;; (void)area(a);                   //calculate the area and don't care about the return cause it's in assembly and it'd be annoying
;; (void)center(a);                 //calculate the center of the rect (extract the origin)
;; (void)contains(a, b);            //calculated if the point is in the rect (deer god)
;
;into asm, this means 3 functions and a main.
;
;so that's Point fitting in one register (2 32 bit numbers (int))
;and that's Rect having to fit in on the stack ((4+4)+4+4+4), i might want a masm macro for copying rects
;the functions take by value, so i have to copy the godforsaken structs on memory
;the Rect struct doesn't actually have a Point struct anywhere, it's equivalent to a flat struct
;-------------------------------------------------------------------------------

;;; entry point, also known to the C runtime as void main()
_start:
    ;; Point a = Point(4, 3);
    mov r12d, 3                 ;Point a.y, using r12 as it's callee saved
    shl r12, 32                 ;shift left 32 bits (pack)
    or r12, 4                   ;Point a.x, using or to leave the high bits untouched, and not using 12d to not zero extend
    ;; Rect a = Rect(a, 4, 2, 0);
    sub rsp, 32                 ;move the stack down 32 bytes (16 alligned)
    mov rax, r12                ;ready up the struct for copying
    mov DWORD [rsp], eax        ;a.x
    shr rax, 32                 ;shift right to get a.y
    mov DWORD [rsp+4], eax      ;a.y
    mov DWORD [rsp+8], 4        ;width
    mov DWORD [rsp+12], 2       ;height
    mov DWORD [rsp+16], 0       ;colour
    ;; Rect b = Point(2, 3)
    mov r13d, 3                 ;Point b.y, r13 is callee saved again so it's safe
    shl r13, 32                 ;pack
    or r13, 2                   ;Point b.x
    ;; (void)area(a); -> int
    lea rax, [rsp]              ;save the rsp address for easier indexing (not needed, but saves me some pain)
    sub rsp, 32                 ;make more space on the stack for copying the struct by value, fun fact, large structs in C are usually passed by reference with "const", in asm there's no const but the rule still applies
    mov edx, [rax]              ;intermediate
    mov DWORD [rsp], edx        ;a.x
    mov edx, [rax+4]            ;intermediate
    mov DWORD [rsp+4], edx      ;a.y
    mov edx, [rax+8]            ;intermediate
    mov DWORD [rsp+8], edx      ;width
    mov edx, [rax+12]           ;intermediate
    mov DWORD [rsp+12], edx     ;height
    mov edx, [rax+16]           ;intermediate
    mov DWORD [rsp+16], edx     ;colour
    lea rdi, [rsp]              ;ready first argument (rect a)
    call area                   ;call the function
    add rsp, 32                 ;free the pass-by-value struct
    ;; (void)center(a); -> Point
    lea rax, [rsp]              ;save the rsp address for easier indexing (not needed, but saves me some pain)
    sub rsp, 32                 ;make more space on the stack for copying the struct by value, fun fact, large structs in C are usually passed by reference with "const", in asm there's no const but the rule still applies
    mov edx, [rax]              ;intermediate
    mov DWORD [rsp], edx        ;a.x
    mov edx, [rax+4]            ;intermediate
    mov DWORD [rsp+4], edx      ;a.y
    mov edx, [rax+8]            ;intermediate
    mov DWORD [rsp+8], edx      ;width
    mov edx, [rax+12]           ;intermediate
    mov DWORD [rsp+12], edx     ;height
    mov edx, [rax+16]           ;intermediate
    mov DWORD [rsp+16], edx     ;colour
    lea rdi, [rsp]              ;ready first argument (rect a)
    call center                 ;function call, slight tangent, on longer copies this becomes really slow and tedious to write out, so you either move by reference or use "rep movsd" which basically functions as memcpy in c, in fact it's so good it's a lot faster on larger structs: lea rdi, [rsp]; lea rsi [rsp]; mov ecx, 5; rep movsd; will copy 5 (ecx) dwords from [rsi] to [rdi], it's very useful. not in my case since it's 5 fields and it's just faster to unroll it.
    add rsp, 32                 ;free the pass-by-value struct
    ;; (void)contains(a, b); -> int (0|1)
    lea rax, [rsp]              ;save the rsp address for easier indexing (not needed, but saves me some pain)
    sub rsp, 32                 ;make more space on the stack for copying the struct by value, fun fact, large structs in C are usually passed by reference with "const", in asm there's no const but the rule still applies
    mov edx, [rax]              ;intermediate
    mov DWORD [rsp], edx        ;a.x
    mov edx, [rax+4]            ;intermediate
    mov DWORD [rsp+4], edx      ;a.y
    mov edx, [rax+8]            ;intermediate
    mov DWORD [rsp+8], edx      ;width
    mov edx, [rax+12]           ;intermediate
    mov DWORD [rsp+12], edx     ;height
    mov edx, [rax+16]           ;intermediate
    mov DWORD [rsp+16], edx     ;colour
    lea rdi, [rsp]              ;ready first argument (rect a)
    mov rsi, r13                ;ready second argument (point b)
    call contains               ;function call
    add rsp, 64                 ;free stack
exit:
    mov rax, syscallExit        ;exit()
    xor edi, edi                ;that's the part that actually does the 0 code
    syscall                     ;terminate the program

;;; functions :3
area:                           ;int area(Rect)
    ;; expected variables: a 20 byte rect in [rsp+8] through [rsp+20], 5 ints: xpos ypos width height colour
    ;; returning an int representing the area of a rect, take width and height and multiply them.
    ret

center:                         ;Point center(Rect)
    ;; expected variables: a 20 byte rect in [rsp+8] through [rsp+20], 5 ints: xpos ypos width height colour
    ;; returning an 8 byte struct in rax, 2 ints: xpos ypos
    ret

contains:                       ;int contains(Rect r, Point p)
    ;; expected variables: a 20 byte rect in [rsp+8] through [rsp+20], 5 ints: xpos ypos width height colour, an 8 byte struct in rdi, 2 ints: xpos ypos
    ret

;===============================================================================
