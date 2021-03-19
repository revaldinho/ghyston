        # NQUEENS benchmark
        #
        # Recoded from the BASIC version on
        #
        # http://www.hpmuseum.org/cgi-sys/cgiwrap/hpmuseum/articles.cgi?read=700
        #
        # Result is stored in A[1..8] (ie not starting at 0) for a board numbered
        #
        #    1 2 3 4 5 6 7 8
        #  1   # Q #   #   #    First Solution = 8,4,1,3,6,2,7,5
        #  2 #   #   # Q #
        #  3   #   Q   #   #
        #  4 # Q #   #   #
        #  5   #   #   #   Q
        #  6 #   #   Q   #
        #  7   #   #   # Q #
        #  8 Q   #   #   #
        #

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

        ORG     0x000
        EQU     NQUEENS, 8        # set number of queens and n x n board (usu 8)

        mov     r12,STACK_TOP
        jsr     pd_init
start:
        mov     r8, NQUEENS     # r8 == R
        mov     r11,0           # r11 == S
        mov     r10,0           # r10 == X
        mov     r9,0            # r9  == Y
L40:    cmp     r10,r8          # L1: IF X=R THEN L140 (all results)
        bra  nz L40s            # Skip display if X!=R
        jsr     display_result
        bra     L140            # Run another iteration
L40s:
        add     r10,r10,1       # X = X+1
        add     r0, r10, results
        sto     r8,r0           # A(X)=R
L70:    add     r11, r11,1      # S = S+1
        mov     r9,r10          # Y = X
L90:    sub     r9, r9,1        # Y = Y-1
        bra z   L40             # IF Y=0 THEN L40
        add     r0, r10, results
        ld      r1,r0           # r1 = A(X)
        add     r0, r9, results
        ld      r2,r0           # r2 = A(Y)
        sub     r1,r1, r2       # T= A(X)-A(Y)
        bra z   L140            # IF T=0 THEN L140
        bra pl  L90a
        not     r1,r1           # T = ABS(T)
        add     r1,r1,1         # IF X-Y != ABS(T) GOTO L90
L90a:
        sub     r1,r1,r10       # [if ABS(T)-X+Y!=0]
        add     r1,r1,r9        #
        bra nz  L90

L140:   add     r0, r10, results
        ld      r1,r0           # r1 = A(X)
        sub     r1, r1, 1
        sto     r1, r0          # A(X) = A(X)-1
        bra nz  L70             # IF A(X) GOTO L70
        DJNZ    (r10,L140)      # X = X-1: IF X GOTO L140
L180:   mov     r2,0
        mov     r1,r11
        jsr     printdec32      # Print S
        PRINT_NL ()
        HALT    ()
end:    bra     end

display_result:
        PUSHALL ()
        # Dump contents of the results area (from index 1 upwards)
        PRINT_NL()
        mov     r10,0
P1:     add     r0,r10,results+1
        ld      r1,r0
        WRDIG   (r1)        # Print digit and space
        WRCH    (32)
        add     r10,r10,1
        cmp     r10, NQUEENS
        bra nz  P1
        PRINT_NL()
        PRINT_NL()

        # Now attempt to show the results on a matrix, header first
        WRCH  (32)         # SPACE
        WRCH  (32)         # SPACE
        WRCH  (32)         # SPACE
        mov     r8,1
P2:     WRDIG   (r8)
        WRCH  (32)         # SPACE
        add     r8,r8, 1
        cmp     r8, NQUEENS+1
        bra  mi P2
        PRINT_NL()

        # Now print row by row
        mov     r8, 1
P3:     WRDIG   (r8)       # row number
        WRCH    (32)        # SPACE
        add     r0, r8, results
        ld      r6,r0       # get Q column number
        mov     r5, 1
P4:     WRCH    (32)        # SPACE
        cmp     r5,r6
        bra z   P5
        WRCH    (32)
        add     r5, r5, 1
        bra     P4

P5:     WRCH    ( 113 )      # ASCII Q
        PRINT_NL()
        add     r8, r8, 1
        cmp     r8, NQUEENS+1
        bra nz  P3
        POPALL  ()
        ret     r14

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
        mov     r3, 10
pdi_0:  sto     r2, r1
        add     r1, r1, 1
        mul     r2, r2, 10
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
        cmp     r3,r5           # Is number > decimal divisor
        bra  le pd32_l2         # If no then skip ahead and decide whether to print the digit
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
