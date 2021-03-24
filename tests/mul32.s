
#include "options.h"
#include "macros.h"

MACRO   MUL    ( _num1_ , _num2_ )
        movi    r1, _num1_ & 0xFFFF
        movti   r1, (_num1_ >> 16) & 0xFFFF
        movi    r2, _num2_ & 0xFFFF
        movti   r2, (_num2_ >> 16) & 0xFFFF
        jsr     test_mul
ENDMACRO

        ORG     0x00

        movi    r12,STACK_TOP

        MUL    ( 3, 3 )
        MUL    ( 27, 108 )
        MUL    ( 1023, 5467 )
        MUL    ( 8, 120394 )
        MUL    ( 1294, 5748 )
        MUL    ( 16387, 123456 )

        HALT    ()

test_mul:
        mov     r10, r1         ; save numbers
        mov     r9, r2 
        
        PUSH    (r14)

        mov     r1, m0
        jsr     sprint
        mov     r1, r10
        jsr     printdec32
        mov     r1, 44
        jsr     oswrch
        mov     r1, r9
        jsr     printdec32        
        mov     r1, m1
        jsr     sprint
        mov     r1, r10        
        jsr     qmul32
        jsr     printdec32
        PRINT_NL()
        POP     (r14)
        ret     r14

#include "include/intmath.s"
#include "include/stdio.s"

;;;  DATA Area definitions
        DATA

m0:     BSTRING "MUL(\0"
m1:     BSTRING ") = \0"
results:

        EQU     STACK_TOP,      0x1FF
