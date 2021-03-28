;;
;; Program to generate E using the Spigot Algorithm from
;;
;; http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
;;
;; Translated from the OPC7 version

#include "options.h"
#include "macros.h"

        # r14 = link register
        # r12 = inner loop counter
        # r11 = Q
        # r10 = (i+1) value in main loop
        # r9  = outer loop counter
        # r4,5,6,7 = unused
        # r1..r3  = local registers

        EQU     digits,   32            # Digits to be printed
        EQU     cols,     digits+2      # Needs a few more columns than digits to avoid occasional errors in last digit or few

        ORG 0
        ;; trivial banner + first digit and decimal point
        ;; trivial banner
        mov     r12, 0x3FF
        WRCH    (0x4f)
        WRCH    (0x6b)
        WRCH    (0x20)
        WRDIG   (2)
        WRCH    (0x2E)

                                        # Initialise remainder array
        mov     r2,1                    # r2=const 1
        mov     r3,cols-1               # loop counter i starts at index = RHS
L1:     add     r0, r3, remain
        sto     r2, r0                  # store remainder value to pointer
        DJNZ    (r3, L1)                # decrement loop counter and loop again if not zero
        mov     r0, 0
        sto     r0,remain               # write 0 into first entry

        mov     r9,digits               # set up outer loop counter
L3:     mov     r11,0                   # r11 = Q
        mov     r12,cols                # r12 = (i+1) inner loop counter start at RHS of array
                                        # ie need to refer to i+1 in loop and will offset the base
                                        # of the remain data to access remain[i] by -1. Using (i+1) as the counter also
                                        # allows use of DJNZ at the bottom of the loop, exiting when (i+1)=0
L4:
        add     r0,r12,remain-1
        ld      r2,r0                   # r2 <- remain[i]
#ifdef MUL18X18
        mul     r2,r2,10
        add     r1,r11,r2
#else
        asl     r2,r2, 1                # Compute 16b result for r2 * 10 and add to r11
        add     r11,r11,r2              # ..first add 2*r2
        asl     r2,r2,2
        add     r1,r11,r2              # now add 8*r2 for total of 10*r2
#endif
        mov     r2, r12
        jsr     udiv1632                # r11/r10; r11 <- quo, r2 <- rem, r10 preserved
        mov     r11, r1
        add     r0, r12, remain-1
        sto     r2, r0                  # rem[i] <- r2

        DJNZ    (r12, L4)

L6:     WRDIG   (r11)                   # Convert quotient into ASCII digit

L7:
        DJNZ    (r9, L3)                # dec loop counter and jump back to main program

        WRCH    (10)                    # Print Newline to finish off
        WRCH    (13)
        HALT    ()
end:    bra     end


        #include "include/intmath.s"
        #include "include/stdio.s"

        DATA
        ; DATA MEM defines after any local memory for include files
remain:
