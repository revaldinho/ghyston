        ;; Recursive factorial program

#include "options.h"
#include "macros.h"

MACRO MUL (_a_, _b_ )
#ifdef MUL_INSTR
        mul     _a_, _a_, _b_
#else
        mov     r1, _a_
        mov     r2, _b_
        jsr     qmul32
#endif
ENDMACRO

        ORG     0000
        EQU     MAX, 13
        mov     r12, STKTOP

        mov     r5, 1
loop:   mov     r1, msg1
        jsr     sprint
        mov     r1, r5
        jsr     printdec32
        mov     r1, msg2
        jsr     sprint
        mov     r1, r5
        jsr     fact
        jsr     printdec32
        PRINT_NL        ()
        add     r5, r5, 1
        cmp     r5, MAX
        bra nz  loop
        HALT ()


fact:   cmp     r1, 0
        ret  z  r14
        cmp     r1, 1
        ret  z  r14
        PUSH    (r14)
        PUSH    (r1)
        sub     r1,r1,1
        jsr     fact
        POP     (r2)
        MUL     (r1,r2)
        POP     (r14)
        ret     r14



#include "include/intmath.s"
#include "include/stdio.s"

        DATA
msg1:   BSTRING "FACT(\0"
msg2:   BSTRING ") = \0"
        EQU     STKTOP,         0x3FF
