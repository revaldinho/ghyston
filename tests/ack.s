        ;; Ackermann's function test
        ;;
        ;;   FOR i = 0 TO 3 DO
        ;;   { writef("a(%n, **): ", i)
        ;;     FOR j = 0 TO 6 DO
        ;;       writef(" %i8", ack(i, j))
        ;;     newline()
        ;;     newline()
        ;;   }
        ;;   RESULTIS 0
        ;;         }


#include "options.h"
#include "macros.h"

        ORG     0x00
        EQU     MAX_X, 4
        EQU     MAX_Y, 5
        movi    r12,STACK_TOP
        jsr     pd_init

        mov     r6, 0
loop1:
        mov     r5, 0
loop:   jsr     acktest
        add     r5,r5, 1
        cmp     r5, MAX_X
        bra nz  loop
        add     r6,r6, 1
        cmp     r6, MAX_Y
        bra nz  loop1
        HALT    ()
end:    bra end


acktest:

        PUSH    (r14)
        mov     r1, m1
        jsr     sprint
        mov     r1, r5
        jsr     printdec32
        mov     r1, 44          ; comma
        jsr     oswrch
        mov     r1, r6
        jsr     printdec32
        mov     r1, m2
        jsr     sprint
        mov     r1, r5
        mov     r2, r6
        jsr     ack
        jsr     printdec32
        PRINT_NL ()
        POP     (r14)
        ret     r14

        ;; ----------------------------------------
        ;; Ackermann's Function
        ;; ----------------------------------------
        ;; LET ack(x, y) = x=0 -> y+1,
        ;;                 y=0 -> ack(x-1, 1),
        ;;                 ack(x-1, ack(x, y-1))
        ;; ----------------------------------------
        ;; Entry:
        ;;   r1 = x
        ;;   r2 = y
        ;; Exit
        ;;   r1 = val
        ;; ----------------------------------------
ack:    PUSH    (r14)
        cmp     r1, 0
        bra  z  ack1
        cmp     r2, 0
        bra  z  ack2
        sub     r3,r1,1         ; X-1
        PUSH    (r3)
        sub     r2,r2,1         ; Y-1
        jsr     ack             ; ACK(X, Y-1)
        mov     r2, r1          ; move to Y
        POP     (r1)            ; restore X
        jsr     ack
        POP     (r14)
        ret
ack1:
        add     r1, r2, 1       ; return VAL=Y+1
        POP     (r14)
        ret
ack2:
        sub     r1, r1, 1       ; return ACK(X-1,1)
        mov     r2, 1
        jsr     ack
        POP     (r14)
        ret

        # ------------------------------------------------------------
        # printdec32
        #
        # Print unsigned decimal integer from a 32b number to console
        # suppressing leading zeroes
        #
        # Entry:
        #       r1  holds 32 b number to print
        # Exit:
        #       r5-r14 preserved
        #       r1-r4 used for workspace
        # ------------------------------------------------------------
        # Register usage
        # r9    = Decimal table pointer for repeated subtraction
        # r8    = Q (quotient)
        # r7    = Leading zero flag (nonzero once a digit is printed)
        # r5,r6 = Divisor for each round of subtraction
        # r3,r4 = Remainder (eventually bits only in r3)
        # ------------------------------------------------------------

pd_init:
        # Initialise divisor table for printdec32,
        mov     r1, pd32_table
        mov     r2, 10
        mov     r3, 9
pdi_0:  sto     r2, r1
        add     r1, r1, 1

        asl     r0, r2, 1
        asl     r2, r2, 3
        add     r2, r0, r2
        DJNZ    (r3, pdi_0)
        ret     r14

printdec32:
        PUSHALL    ()           # Save all registers above r4 to stack
        mov     r7,0            # leading zero flag
        mov     r9,9            # r9 points to end of 9 entry table (numbered 1-9 to allow use of DJNZ)
        mov     r3,r1           # move number into r3 to sav juggling over oswrch call
pd32_l1:
        add     r0, r9, pd32_table-1
        ld      r5,r0           # get 32b divisor from table low word first
        mov     r8, 0           # set Q = 0
pd32_l1a:
        cmp     r3,r5           # Is number >= decimal divisor
        bra  lt pd32_l2         # If no then skip ahead and decide whether to print the digit
        sub     r3,r3, r5       # If yes, then do the subtraction
        add     r8,r8,1         # Increment the quotient
        bra     pd32_l1a        # Loop again to try another subtraction

pd32_l2:
        add     r1,r8,48        # put ASCII val of quotient in r1
        add     r7,r7,r8        # Add digit into leading zero flag
        bsr     nz oswrch       # Print only if the leading zero flag is non-zero

pd32_l3:
        DJNZ    (r9, pd32_l1)   # Point at the next divisor in the table and loop again if not zero
        add     r1,r3,48        # otherwise convert remainder low word to ASCII
        jsr     oswrch          # and print it
        POPALL  ()              # Restore all high registers and return
        ret
        ; --------------------------------------------------------------
        ;
        ; sprint
        ;
        ; Print a string to stdout
        ;
        ; Entry:
        ;       r1 is the address of a zero terminated string to print
        ; Exit:
        ;       r0-r3 trashed
        ; ---------------------------------------------------------------
sprint:
        PUSH    (r14, r12)
        PUSH    (r5, r12)
        PUSH    (r4, r12)
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
spl3:   POP     (r4, r12)
        POP     (r5, r12)
        POP     (r14,r12)
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


;;;  DATA Area definitions
        DATA
        ORG     0x00
m1:     BSTRING "Ack(\0"
m2:     BSTRING ") = \0"
pd32_table:
        WORD    0

        EQU     STACK_TOP,  0x0FFF
        EQU     pd32_table_sz, 10
        EQU     results, pd32_table + pd32_table_sz + 1