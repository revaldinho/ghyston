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
        mov  r1, RESULTS
        mov  r5,r1
        mov  r1, 0
        mov  r2, 1
        mov  r3, 5        
        sto.w r1, r5
        add   r5, r5, 4
LOOP:
        sto.w r2, r5
        add   r4, r1, r2
        mov   r1, r2
        mov   r0, r0
        mov   r2, r4
        add   r5, r5, 4  
        sub   r3, r3, 1
        bcc   nz LOOP
        # these instructions will get fetched but should NOT complete 'til
        # the loop is done
        mov   r2,r0
        mov   r2,r0
        mov   r5,r0

END:    
        bra END

END2:
        bra END2


## DATA SECTION - LABELS for use in BYTE ORIENTED DMEM
        
        ORG 0
        
        WALIGN
RESULTS:        
