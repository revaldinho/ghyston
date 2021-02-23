        


        ORG     0
        jmp     START



        ORG     0x100
START:
        movi   r3, RESULTS
        movi   r1, 0x0101
        movi   r2, 0x0010
        jsr     qmul32b
        sto.w   r1, r3
        add     r3, r3,4
        movi   r1, 0x0100
        movi   r2, 0x0110
        jsr     qmul32b
        sto.w   r1, r3
        add     r3, r3,4
END:
        bra     END
        

        ORG 0x0200
        # -----------------------------------------------------------------
        #
        # qmul32
        #
        # Quick multiply 2 32 bit numbers and return a 32 bit number  without
        # checking for overflow conditions
        #
        # Entry
        # - R1 holds A
        # - R2 holds B
        # - R14 holds return address
        #
        # Exit
        # - R1 holds product of A and B
        # - R0 used as workspace and trashed
        # - all other registers preserved
        #
        # Register Usage
        # - R1 = Product Register
        # - R0 = holds first shifted copy of A
        # ------------------------------------------------------------------        
qmul32b:
        lsr      r0, r1, 1       # shift A into r0
        mov      r1, 0           # initialise product (preserve C)
qm32_1b:
        bra  nc  qm32_2b
        add      r1, r1, r2      # add B into acc if carry
qm32_2b:
        asl      r2, r2, 1       # multiply B x 2
        lsr      r0, r0, 1       # shift A to check LSB
        bra  nz  qm32_1b         # if A is zero then exit else loop again (preserving carry)
        ret  nc  r14             # return if no carry
        add      r1, r1, r2      # Add last copy of multiplicand into acc if carry was set
        ret      r14             # return

        # DATA MEMORY
        ORG 0
RESULTS:
        
