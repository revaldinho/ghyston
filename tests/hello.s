        ;; Hello World
        ;;
        ;; Simple test of string handling
#include "options.h"
#include "macros.h"

        ORG     0x0000
        movi    r12, stack_top

        movi    r1, msg
        jsr     sprint

        HALT    ()

        ; --------------------------------------------------------------
        ;
        ; sprint
        ;
        ; Print a string to stdout
        ;
        ; Entry:
        ;       r1 is the address of a zero terminated string to print
        ; Exit:
        ;       r0-r5 trashed
        ; ---------------------------------------------------------------
sprint:
        PUSH    (r14, r12)
        mov     r3, r1
spl1:   mov     r4, 4
        ld      r5, r3
spl2:   and     r1, r5, 0xFF
        bra  z  spl3
        jsr     oswrch
        lsr     r5, r5, 8
        DJNZ    (r4, spl2)
        add     r3, r3, 1
        bra     spl1
spl3:   POP     (r14,r12)
        ret     r14
        ; --------------------------------------------------------------
        ;
        ; oswrch
        ;
        ; Output a single ascii character to the uart
        ;
        ; Entry:
        ;       r1 is the character to output
        ; Exit:
        ;       r0 used as temporary
        ; ---------------------------------------------------------------
oswrch:
oswrch_loop:
        movi    r0, 0xFFFE
        movti   r0, 0x00FF
        sto.w   r1, r0
        ret     r14

        # data Section
        DATA
        ORG     0x0

msg:    BSTRING "Hello, World!\r\0"
        EQU     stack_top, 0x01FF
