#include "options.h"
#include "macros.h"
        
        ORG    0
        EQU    RESULTS, 0


        movi    r3, 0x1234
        movti   r3, 0x5678
        mov     r1, RESULTS
        mov     r4, 31
LOOP:   btst    r3, r4
        bra  nz one
        mov     r2, 0
        bra     next
one:    mov     r2, 1
next:
        sto     r2, r1
        add     r1, r1, 1
        sub     r4, r4, 1
        cmp     r4, 0
        bra  pl LOOP

        movi    r3,0
        mov     r4, 31
LOOP1:  bset r3, r3, r4
        sto     r3, r1
        add     r1, r1, 1
        sub     r4, r4, 1
        cmp     r4, 0
        bra pl   LOOP1
        mov     r4, 31
LOOP2:  bclr    r3, r3, r4
        sto     r3, r1
        add     r1, r1, 1
        sub     r4, r4, 1
        cmp     r4, 0
        bra pl   LOOP2


END:    HALT    ()
        bra     END

        EQU RESULTS, 0
