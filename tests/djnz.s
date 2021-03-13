#define  DJNZ   1



MACRO   HALT( )
        movi    r0, 0xFFFF
        movti   r0, 0x00FF
        sto     r0, r0
ENDMACRO

MACRO   DJNZ ( _reg_, _label_)
#ifdef DJNZ
        djnz    _reg_, _reg_, _label_
#else
        sub     _reg_, _reg_, 1
        bra nz  _label_
#endif
ENDMACRO



        ORG    0
        EQU    RESULTS, 0

        movi    r0, RESULTS
        mov     r1, 10


loop:
        sto     r0,r0
        add     r0, r0,1
        DJNZ    (r1, loop)

END:    HALT    ()
        bra     END

        
