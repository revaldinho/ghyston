MACRO   WRCH( _reg_or_data_ )
        mov     r1, _reg_or_data_
        jsr     oswrch
ENDMACRO

MACRO   WRDIG( _reg_or_data_ )
        mov     r1, _reg_or_data_
        add     r1, r1, 48
        jsr     oswrch
ENDMACRO

MACRO   HALT( )
        movi    r0, 0xFFFF
        movti   r0, 0x00FF
        sto     r0, r0
@end:   bra     @end
ENDMACRO

MACRO   DJNZ ( _reg_, _label_)
#ifdef DJNZ_INSTR
        djnz    _reg_, _reg_, _label_
#else
        sub     _reg_, _reg_, 1
        bra nz  _label_
#endif
ENDMACRO

MACRO   PUSH( _data_)
        sub     r12, r12, 1
        sto     _data_, r12
ENDMACRO

MACRO   POP( _data_ )
        ld      _data_, r12
        add     r12, r12, 1
ENDMACRO

MACRO   PUSHALL()
        PUSH (r14)
        PUSH (r11)
        PUSH (r10)
        PUSH ( r9)
        PUSH ( r8)
        PUSH ( r7)
        PUSH ( r6)
        PUSH ( r5)
ENDMACRO

MACRO   POPALL()
        POP ( r5)
        POP ( r6)
        POP ( r7)
        POP ( r8)
        POP ( r9)
        POP (r10)
        POP (r11)
        POP (r14)
ENDMACRO

MACRO   PRINT_NL ()
        WRCH(10)
        WRCH(13)
ENDMACRO
