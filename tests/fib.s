#include "options.h"
#include "macros.h"

        ORG     0000
        mov     r12, STKTOP
fib:
        mov     r7, 0     # r7 = 0
        mov     r8, 1     # r8 = 1

fibLoop:
        add     r7, r7, r8
        bra c   fibEnd
        mov     r1, r7
        jsr     printdec32
        PRINT_NL        ()
        add     r8, r8, r7
        bra c   fibEnd
        mov     r1, r8
        jsr     printdec32
        PRINT_NL        ()
        bra     fibLoop
fibEnd:
        HALT ()

#include "include/stdio.s"

        DATA
        EQU     STKTOP,         0x3FF
