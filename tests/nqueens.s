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

#include "options.h"
#include "macros.h"

        ORG     0x000
        EQU     NQUEENS, 8        # set number of queens and n x n board (usu 8)

        mov     r12,STACK_TOP
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
#ifdef ZLOOP_INSTR        
        zloop   L140
#endif        
L90:    sub     r9, r9,1        # Y = Y-1
        bra z   L40             # IF Y=0 THEN L40
        add     r0, r10, results
        ld      r1,r0           # r1 = A(X)
        add     r0, r9, results
        ld      r2,r0           # r2 = A(Y)
        sub     r1,r1, r2       # T= A(X)-A(Y)
        bra z   L140            # IF T=0 THEN L140
        bra pl  L90a
                                # T = ABS(T)
                                # IF X-Y != ABS(T) GOTO L90
#ifdef NEG_INSTR
        neg     r1, r1          # get 2s complement in single instruction
#else
        movi    r0, 0
        sub     r1, r0, r1
#endif
L90a:
        sub     r1,r1,r10       # [if ABS(T)-X+Y!=0]
        add     r1,r1,r9        #
#ifdef ZLOOP_INSTR        
        bra z  L140             # breakout if counter reaches zero
#else        
        bra nz  L90             # loop again while not zero
#endif

L140:
        add     r0, r10, results
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

#include "include/stdio.s"
        ;;  DATA Area definitions
        DATA
results:
        EQU     STACK_TOP,      0x3F
