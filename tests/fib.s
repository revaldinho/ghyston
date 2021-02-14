        MACRO MOV ( _rdest_, _rsrc_ )
        and _rdest_, _rsrc_, _rsrc_
        ENDMACRO
        
        ORG 0000

## Start Vector        
        jmp START
## Interrupt vectors        
L1:     WORD 00
        WORD 00
        WORD 00
        WORD 00
        WORD 00
        WORD 00                

START:
        # NB Data RAM is BYTE addressed
        movi  r5, RESULTS+4
        movi  r1, 0
        movi  r2, 1
        movi  r3, 5
        sto.w r1, r5,-4
LOOP:
        sto.w r2, r5
        add   r4, r1, r2
        MOV   (r1, r2)
        MOV   (r2, r4)
        add   r5, r5, 4  
        sub   r3, r3, 1
        bcc   nz LOOP
        # these instructions will get fetched but should NOT complete 'til
        # the loop is done
        MOV   (r2,r0)
        MOV   (r2,r0)
        MOV   (r5,r0)

END:    
        bra END

END2:
        bra END2


## DATA SECTION - LABELS for use in BYTE ORIENTED DMEM
        
        ORG 0
        
        WALIGN
RESULTS:        
