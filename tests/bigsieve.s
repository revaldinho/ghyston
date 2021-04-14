        ;;
        ;; bigsieve.s
        ;;
        ;; Find all prime numbers less than a given maximum
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

#include "options.h"
#include "macros.h"

        ORG     0x0000
        EQU   MAX, 1024                    # set max number to sift through

        movi    r12, stack_top
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
        movi    r2,1+MAX//64   # 32 entries per word but store only odd flags
        mov     r0, 0
        mov     r1, r2
L0:     add     r3, r1, results-1
        sto     r0,r3
        DJNZ    (r1, L0)

        # output 2 to console - first prime number
        WRDIG    (2)
        PRINT_NL ()

        mov     r11,3            # Start sieve at first odd number
L1:     mov     r1,r11           # Copy pointer val into r1
        jsr     getbit           # Is bit set ?
        bra nz  L3               # If yes then next bit else...

        mov     r1,r11
        jsr     printdec32
        PRINT_NL ()

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

#include "include/stdio.s"

        # data Section
        DATA
results:
        EQU     stack_top, 0x03F
