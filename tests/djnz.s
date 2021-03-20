#include "options.h"
#include "macros.h"

        ORG    0
        EQU    RESULTS, 0

        movi    r0, RESULTS
        mov     r1, 10


loop:
        sto     r0,r0
        add     r0, r0,1
        DJNZ    (r1, loop)

END:    HALT    ()
        bra     END

        
