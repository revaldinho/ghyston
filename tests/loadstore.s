 


        MACRO MOV ( _rdest_, _rsrc_ )
        and _rdest_, _rsrc_, _rsrc_
        ENDMACRO
        
        ORG 0000

        jmp START

L1:     WORD 00
        WORD 00
        WORD 00
        WORD 00
        WORD 00
        WORD 00                

        

START:
        movi  r5, RESULTS
        movi  r4, 10
        movi  r3, 0x1234
        movi  r3, 0x0000
        movti r3, 0xAAAA

WLOOP:
        sto.w   r3, r5
        ld.w    r6, r5
        add     r3, r6, 1
        add     r5, r5, r0, 4
        sub     r4, r4, r0, 1
        bcc nz WLOOP
        
END:    
        bra END

# data section

        ORG 0
        WALIGN
RESULTS:        
