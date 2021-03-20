        #define DJNZ_INSTR 1
MACRO   WRCH( _reg_or_data_ )
        mov     r1, _reg_or_data_
        jsr     oswrch
ENDMACRO

MACRO   WRDIG( _reg_or_data_ )
        mov     r1, _reg_or_data_
        add     r1, r1, 48
        jsr     oswrch
ENDMACRO

MACRO   HALT( )
        movi    r0, 0xFFFF
        movti   r0, 0x00FF
        sto     r0, r0
ENDMACRO

MACRO   DJNZ ( _reg_, _label_)
#ifdef DJNZ_INSTR
        djnz    _reg_, _reg_, _label_
#else
        sub     _reg_, _reg_, 1
        bra nz  _label_
#endif
ENDMACRO

MACRO   PUSH( _data_)
        sub     r12, r12, 1
        sto     _data_, r12
ENDMACRO

MACRO   POP( _data_ )
        ld      _data_, r12
        add     r12, r12, 1
ENDMACRO

MACRO   PUSHALL()
        PUSH (r14)
        PUSH (r11)
        PUSH (r10)
        PUSH ( r9)
        PUSH ( r8)
        PUSH ( r7)
        PUSH ( r6)
        PUSH ( r5)
ENDMACRO

MACRO   POPALL()
        POP ( r5)
        POP ( r6)
        POP ( r7)
        POP ( r8)
        POP ( r9)
        POP (r10)
        POP (r11)
        POP (r14)
ENDMACRO

MACRO   PRINT_NL ()
        WRCH(10)
        WRCH(13)
ENDMACRO


MACRO   SQRT    ( _num_ )
        movi    r1, _num_ & 0xFFFF
        movti   r1, (_num_ >> 16) & 0xFFFF
        jsr     test_sqrt
ENDMACRO

        ORG     0x00

        movi    r12,STACK_TOP
        jsr     pd_init

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
end:    bra end

test_sqrt:
        mov     r10, r1         ; save number for rooting
        PUSH    (r14)
        mov     r1, ord('S')
        WRCH    (r1)
        mov     r1, ord('q')
        WRCH    (r1)
        mov     r1, ord('r')
        WRCH    (r1)
        mov     r1, ord('t')
        WRCH    (r1)
        mov     r1, ord('(')
        WRCH    (r1)
        mov     r1, r10
        jsr     printdec32
        mov     r1, ord(')')
        WRCH    (r1)
        mov     r1, ord('=')
        WRCH    (r1)
        mov     r1, r10
        jsr     sqrt32
        jsr     printdec32
        PRINT_NL()
        POP     (r14)
        ret     r14

        # -----------------------------------------------------------------
        #
        # sqrt32
        #
        # Find square root of a 32 bit number
        #
        # Entry
        # - R1 holds number to root
        # - R13 holds return address
        #
        # Exit
        # - R1 holds square root
        # - R2,3 used as workspace and trashed
        # - all other registers preserved
        #
        # ------------------------------------------------------------------
        #
        # def isqrt( num) :
        #     res = 0
        #     bit = 1 << 30; ## Set second-to-top bit, ie b30 for 32 bits
        #     ## "bit" starts at the highest power of four <= the argument.
        #     while (bit > num):
        #         bit >>= 2
        #     while (bit != 0) :
        #         num -= res + bit
        #         if ( num >= 0 ):
        #             res = (res >> 1) + bit
        #         else:
        #             num += res + bit
        #             res >>= 1
        #         bit >>= 2
        #     return res
        #
        # ------------------------------------------------------------------
sqrt32:
        mov     r2, r1          # move number to root into r2         
        movi    r1,0            # zero result
        bset    r3, r1, 30      # set bit to 0x40000000
sq32_L1:
        cmp     r2, r3          # compare number with bit
        bra pl  sq32_L2         # exit loop if number >= bit
        asr     r3,r3,2         # shift bit 2 places right
        bra     sq32_L1

sq32_L2:
        cmp     r3,0            # is R3 zero ? 
        ret z   r14             # Yes ? then exit
        add     r0,r1,r3        # Trial subtract r2 -= Res + bit
        sub     r2,r2,r0
        bra mi  sq32_L3         # if <0 then need to restore r2
        asr     r1,r1,1         # shift result right
        add     r1,r1,r3        # .. and add bit
        asr     r3,r3,2
        bra     sq32_L2
sq32_L3:
        add     r2,r2,r0        # restore r2 (add res + bit back)
        asr     r1,r1,1         # shift result right
        asr     r3,r3,2
        bra     sq32_L2

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
        EQU     STACK_TOP,      0x3F
        EQU     pd32_table, 0x040
        EQU     pd32_table_sz, 10
        EQU     results, pd32_table + pd32_table_sz + 1
