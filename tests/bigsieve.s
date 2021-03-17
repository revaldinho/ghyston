        ;;
        ;; bigsieve.s
        ;;
        ;; Find all prime numbers less than ~1.7M limited by memory storage
        ;;
        ;; MAX = 10000
        ;; mem = [0] * MAX
        ;; for ptr in range (2, MAX, 1 ):
        ;;     if not mem[ptr]:
        ;;         for p2 in range (ptr+ptr, MAX, ptr):
        ;;             mem[p2] = 1
        ;;
        ;; ## Read through array and print the primes
        ;; for ptr in range (2, MAX, 1 ) :
        ;;     if not mem[ptr]:
        ;;         print ptr
        ;;
        ;; NB All mem[] markers are packed 32 to a word to save space, so get_bit/set_bit
        ;; routines here need to find the relevant bit in each 32 bit word which holds
        ;; the marker for any given number. In fact we only ever store 'odd' flags to mem[]
        ;; so there's another factor of 2 saving. In 64KWords then we can handle up to
        ;; 64K x 32 = >4M.
        ;;
        ;; Register Usage
        ;;
        ;; r15 = PC
        ;; r12 = SP
        ;; r14 = link
        ;; r11 = 32b outer loop counter (ptr)
        ;; r9  = MAX number to sift
        ;; r7  = inner loop counter (p2)
        ;; ----------------------------------------------------------------------


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

        ORG     0x0000
        EQU   MAX, 1024                    # set max number to sift through

        movi    r12, stack_top
        jsr     pd_init
        # Initialise registers to stop PUSHALL/POPALL ever loading X's to stack for regression runs
        mov     r11,0
        mov     r10,0
        mov     r9,0
        mov     r8,0
        mov     r7,0
        mov     r6,0
        mov     r5,0
        mov     r9, MAX

        # Zero all entries first
        mov     r1,0
        movi    r2,1+MAX//64   # 32 entries per word but store only odd flags
        mov     r0, 0
L0:     add     r3, r1, results
        sto     r0,r3
        add     r1,r1,1
        cmp     r1,r2
        bra nz  L0


        # output 2 to console - first prime number
        WRDIG    (2)
        jsr     newline

        mov     r11,3            # Start sieve at first odd number
L1:     mov     r1,r11           # Copy pointer val into r1
        jsr     getbit           # Is bit set ?
        bra nz  L3               # If yes then next bit else...

        mov     r1,r11
        jsr     printdec32
        jsr     newline

        mov     r7,r11            # p2 <- ptr
L2:
        add     r7,r7,r11         # Increment by ptr
        mov     r1,r7             # Copy number into r1
        jsr     setbit            # Set the bit
        cmp     r7,r9
        bra mi  L2                # Next bit if < MAX

L3:     add     r11,r11,2         # skip even numbers so always increment by 2
        cmp     r11,r9
        bra mi  L1

        HALT    ()
end:    bra end

        # ----------------------------
        # bit
        #
        # Set or check and return the value of an numbered bit in the sieve area, packed 32 to a word
        # and since we never store even flags we can make another factor 2 saving
        # Entry:
        #       r1 = bit number (0< r1 < MAX)
        #       r14 = link register
        # Exit:
        #       Z  = bit value
        #       r2-r4 used for workspace and trashed
        # ----------------------------
getbit:
        lsr     r4,r1,1         # Check if incoming number is even
        bra   c gb1
        or      r1, r1, 1       # if even then set the NZ flag and bail out(ie all even numbers return 1 for sieve)
        ret     r14             # and bail out
gb1:
        lsr     r3,r1,6         # Find the word, first divide original number by 64, ie div by 32 and storing odds only
        lsr     r1,r1,1         # eliminate even bits
        and     r1,r1, 0x001F   # bit position = remainder from original number div 32
        add     r0,r3, results
        ld      r4,r0           # Load the word into r4
        btst    r4,r1           # test the bit setting Z if clear, resetting it if now
        ret     r14

setbit:
        lsr     r4,r1,1         # Check if incoming number is even
        ret nc  r14             # ... and bail out if it is
sb1:
        lsr     r3,r1,6         # Find the word, first divide original number by 64, ie div by 32 and storing odds only
        lsr     r1,r1,1         # eliminate even bits
        and     r1,r1, 0x001F   # bit position = remainder from original number div 32
        add     r0,r3, results
        ld      r4,r0           # Load the word into r4
        bset    r4,r4,r1        # set the bit
        sto     r4,r0           # Write back the word
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
        djnz    r3, r3, pdi_0
        ret     r14

printdec32:
        PUSHALL    ()          # Save all registers above r4 to stack
        mov r7,0               # leading zero flag
        mov r9,8               # r9 points to end of 9 entry table
        mov r3,r1              # move number into r3 to sav juggling over oswrch call
pd32_l1:
        add r0, r9, pd32_table
        ld r5,r0               # get 32b divisor from table low word first
        mov r8, 0              # set Q = 0
pd32_l1a:
        cmp  r3,r5             # Is number > decimal divisor
        bra  le pd32_l2        # If no then skip ahead and decide whether to print the digit
        sub  r3,r3, r5         # If yes, then do the subtraction
        add  r8,r8,1           # Increment the quotient
        bra  pd32_l1a          # Loop again to try another subtraction

pd32_l2:
        add r1,r8,48           # put ASCII val of quotient in r1
        add r7,r7,r8           # Add digit into leading zero flag
        bsr nz oswrch          # Print only if the leading zero flag is non-zero

pd32_l3:
        sub r9,r9,1            # Point at the next divisor in the table
        bra pl pd32_l1         # If entry number >= 0 then loop again
        add r1,r3,48           # otherwise convert remainder low word to ASCII
        jsr oswrch             # and print it
        POPALL  ()             # Restore all high registers and return
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

newline:
        PUSH    (r1)
        PUSH    (r2)
        PUSH    (r14)
        WRCH  (10)
        WRCH  (13)
        POP     (r14)
        POP     (r2)
        POP     (r1)
        ret     r14

        # data Section
        EQU     stack_top, 0x03F
        EQU     pd32_table, 0x040
        EQU     pd32_table_sz, 10
        EQU     results, pd32_table + pd32_table_sz + 1
