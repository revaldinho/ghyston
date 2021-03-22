;;  This program prints the least significant decimal
;;  digit of Connell's sequence numbers An where
;;
;;  An = 2n - int[(1 + sqrt(8i-7))/2]
;;
;;  Translated from Martin Richards' original written
;;  in BCPL
;;
;; LET start() = VALOF
;; { LET prevd = 0
;;
;;   FOR i = 1 TO 2016 DO
;;   { LET d = (2*i - (1+sqrt(8*i-7))/2) REM 10
;;     UNLESS ((prevd NEQV d) & 1) = 0 DO newline()
;;     prevd := d
;;     writef("%n", d)
;;   }
;;   newline()
;;   RESULTIS 0
;; }

#include "options.h"
#include "macros.h"

        ORG     0x00
        EQU     MAX, 512

        movi    r12,STACK_TOP
        jsr     pd_init

        mov     r11, 0          ; r11 = prevd
        mov     r10, 1          ; r10 = i
        movi    r6, MAX

LOOP:   ;; LET d = (2*i - (1+sqrt(8*i-7))/2) REM 10

        asl     r9, r10, 1      ; 2*i
        asl     r8, r10, 3      ; 8*i
        sub     r1, r8, 7       ; (8*i)-7
        jsr     sqrt32          ; sqrt((8*i)-7)
        asr     r1, r1, 1       ; sqrt((8*i)-7)/2
        add     r1, r1, 1       ; 1 + sqrt((8*i)-7)/2
        sub     r1, r9, r1      ; (2*i - (1+sqrt(8*i-7))/2)
        mov     r2, 10
        jsr     udiv32          ; divide by 10 with remainder returned in r2
        mov     r7, r2          ; r7 = d
        xor     r0, r7, r11     ; prevd XOR d
        and     r0, r0, 0x1     ; & 1
        bra  z  NEXT
        PRINT_NL()
NEXT:   mov     r11, r7         ; prevd = d
        mov     r1, r7
        jsr     printdec32
        add     r10, r10, 1     ; next i
        cmp     r10, r6         ; reached MAX ?
        bra le  LOOP
        PRINT_NL()
        HALT    ()

#include "include/intmath.s"

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
        sto     r1, r0
        ret     r14


;;;  DATA Area definitions
        DATA
        ORG     0x00
m0:     BSTRING "Sqrt(\0"
m1:     BSTRING ") = \0"
pd32_table:
        WORD    0x0

        EQU     STACK_TOP,      0x3F
        EQU     pd32_table_sz, 10
        EQU     results, pd32_table + pd32_table_sz + 1
