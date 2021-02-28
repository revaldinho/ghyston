 


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
        sto.w r5, output_ptr
        movi  r4, 10
        movi  r3, 0x1234
        movi  r3, 0x0000
        movti r3, 0xAAAA

WLOOP:
        ld.w    r5, output_ptr
        sto.w   r3, r5
        add     r5,r5,4        

        sto.w   r5, output_ptr
        sub     r3, r3, 1
        bcc nz WLOOP
        
END:    
        bra END

# data section

        ORG 0
output_ptr:
        WORD 0        
        WALIGN
RESULTS:        
