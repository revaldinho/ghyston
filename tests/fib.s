 


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

        sto.w r1, r5,-1 
LOOP:
        sto.w r2, r5
        add   r4, r1, r2
        MOV   (r1, r2)
        MOV   (r2, r4)

        add   r5, r5, 4  # DRAM is BYTE oriented 
        sub   r3, r3, 1
        bra   LOOP
        #bcc  nz LOOP


END:    
        bra END

        WALIGN
RESULTS:        
