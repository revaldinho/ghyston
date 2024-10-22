        ;; ------------------------------------------------------------
        ;; String and digit printing routines
        ;;
        ;; NB requires 10 words of data space which will be declared at the current DATA ORG point
        ;; where the file in included in the main source.
        ;; ------------------------------------------------------------
        ;; ------------------------------------------------------------
        ;; printdec32
        ;;
        ;; Print unsigned decimal integer from a 32b number to console
        ;; suppressing leading zeroes
        ;;
        ;; Entry:
        ;;       r1  holds 32 b number to print
        ;; Exit:
        ;;       r5-r14 preserved
        ;;       r1-r4 used for workspace
        ;; ------------------------------------------------------------
        ;; Register usage
        ;; r11    = Decimal table pointer for repeated subtraction
        ;; r10    = Q (quotient)
        ;; r9    = Leading zero flag (nonzero once a digit is printed)
        ;; r4    = Divisor for each round of subtraction
        ;; r3    = Remainder (eventually bits only in r3)
        ;; ------------------------------------------------------------

printdec32:
        PUSH    (r14)
        PUSH    (r11)
        PUSH    (r10)
        PUSH    (r9)
        PUSH    (r8)
        mov     r9,0            # leading zero flag
        mov     r11,9           # r11 points to end of 9 entry table (numbered 1-9 to allow use of DJNZ)
        mov     r3,r1           # move number into r3 to sav juggling over oswrch call
        movi    r8, pd32_table  # r8 will be incremented before use, but can't assign to pd32_table-1
        sub     r8, r8, 1       # directly since pd32_table could be zero and that needs a 32b assignment to make -1

#ifdef ZLOOP_INSTR
        zloop   pd32_l4
#endif
pd32_l1:
        add     r0, r11, r8
        ld      r4,r0           # get 32b divisor from table low word first
        mov     r10, 0          # set Q = 0
pd32_l1a:
        cmp     r3,r4           # Is number >= decimal divisor
        bra  nc pd32_l2         # If no then skip ahead and decide whether to print the digit
        sub     r3,r3, r4       # If yes, then do the subtraction
        add     r10,r10,1       # Increment the quotient
        bra     pd32_l1a        # Loop again to try another subtraction
pd32_l2:
        add     r1,r10,48       # put ASCII val of quotient in r1
        add     r9,r9,r10       # Add digit into leading zero flag
        bsr     nz oswrch       # Print only if the leading zero flag is non-zero

pd32_l3:
#ifdef ZLOOP_INSTR
        DJZ     (r11, pd32_l4)   # Exit if zero
pd32_l4:
#else
        DJNZ    (r11, pd32_l1)   # Point at the next divisor in the table and loop again if not zero
#endif
        add     r1,r3,48        # otherwise convert remainder low word to ASCII
        jsr     oswrch          # and print it
        POP     (r8)
        POP     (r9)
        POP     (r10)
        POP     (r11)
        POP     (r14)

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
#ifdef ZLOOP_INSTR
        zloop   spl3
#endif
spl1:   mov     r4, 4
        ld      r5, r3
spl2:   and     r1, r5, 0xFF
        bra  z  spl3
        jsr     oswrch
        lsr     r5, r5, 8
        DJNZ    (r4, spl2)
        add     r3, r3, 1
#ifndef LOOP_INSTR
        bra     spl1
#endif
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
        stw     r1, r0
        ret     r14

        ;;  DATA Area will be declared at current DATA pointer
        DATA
pd32_table:
        WORD    10
        WORD    100
        WORD    1000
        WORD    10000
        WORD    100000
        WORD    1000000
        WORD    10000000
        WORD    100000000
        WORD    1000000000

        ;; Revert to CODE on leaving the include file
        CODE
