 


        MACRO MOV ( _rdest_, _rsrc_ )
        and _rdest_, _rsrc_, _rsrc_
        ENDMACRO
        
        ORG 0000

        EQU MYOFFSET, 21

        jmp START

L1:     WORD 00
        WORD 00
        WORD 00
        WORD 00
        WORD 00
        WORD 00                

START:
        movi  r5, RESULTS+4
        MOV   (r1, r0)
        movi  r2, 1
        movi  r3, 10

        sto.w r1, r5,-4
LOOP:
        sto.w r2, r5
        add   r4, r1, r2
        MOV   (r1, r2)
        MOV   (r2, r4)

        add   r5, r5, 4  # DRAM is BYTE oriented 
        sub   r3, r3, 1
        bcc  nz LOOP
        # these instructions will get fetched but should NOT complete 'til
        # the loop is done
        MOV   (r2,r0)
        bra   END2
        MOV   (r5,r0)

END:    
        bra END

END2:
        bra END2


## DATA SECTION - LABELS for use in BYTE ORIENTED DMEM
        
        ORG 0
        
        WALIGN
RESULTS:        
