
#include "options.h"
#include "macros.h"

MACRO   SQRT    ( _num_ )
        movi    r1, _num_ & 0xFFFF
        movti   r1, (_num_ >> 16) & 0xFFFF
        jsr     test_sqrt
ENDMACRO

        ORG     0x00

        movi    r12,STACK_TOP

        SQRT    ( 9 )
        SQRT    ( 27 )
        SQRT    ( 32 )
        SQRT    ( 81 )
        SQRT    ( 120 )
        SQRT    ( 450 )
        SQRT    ( 7880 )
        SQRT    ( 13400 )
        SQRT    ( 59090 )
        SQRT    ( 120000 )
        SQRT    ( 330004 )
        SQRT    ( 5800033 )
        SQRT    ( 10900090 )
        SQRT    ( 659000130 )

        HALT    ()

test_sqrt:
        mov     r10, r1         ; save number for rooting
        PUSH    (r14)

        mov     r1, m0
        jsr     sprint
        mov     r1, r10
        jsr     printdec32
        mov     r1, m1
        jsr     sprint
        mov     r1, r10
        jsr     sqrt32
        jsr     printdec32
        PRINT_NL()
        POP     (r14)
        ret     r14

#include "include/intmath.s"
#include "include/stdio.s"

;;;  DATA Area definitions
        DATA

m0:     BSTRING "Sqrt(\0"
m1:     BSTRING ") = \0"
results:

        EQU     STACK_TOP,      0x1FF
