        ;; -----------------------------------------------------------------
        ;; intmath.s
        ;;
        ;; Integer Maths routines for #including in assembler tests
        ;;
        ;; Ensure that any #defines and instruction macros are defined
        ;; before the #include for this file
        ;; -----------------------------------------------------------------

        ;; -----------------------------------------------------------------
        ;;
        ;; sqrt32
        ;;
        ;; Find square root of a 32 bit number
        ;;
        ;; Entry
        ;; - R1 holds number to root
        ;; - R13 holds return address
        ;;
        ;; Exit
        ;; - R1 holds square root
        ;; - R2,3 used as workspace and trashed
        ;; - all other registers preserved
        ;;
        ;; ------------------------------------------------------------------
        ;;
        ;; def isqrt( num) :
        ;;     res = 0
        ;;     bit = 1 << 30; ## Set second-to-top bit, ie b30 for 32 bits
        ;;     ## "bit" starts at the highest power of four <= the argument.
        ;;     while (bit > num):
        ;;         bit >>= 2
        ;;     while (bit != 0) :
        ;;         num -= res + bit
        ;;         if ( num >= 0 ):
        ;;             res = (res >> 1) + bit
        ;;         else:
        ;;             num += res + bit
        ;;             res >>= 1
        ;;         bit >>= 2
        ;;     return res
        ;;
        ;; ------------------------------------------------------------------

#ifdef ZLOOP_INSTR
sqrt32:
        mov     r2, r1          # move number to root into r2
        movi    r1,0            # zero result
        bset    r3, r1, 30      # set bit to 0x40000000

        zloop   sq32_L2
        cmp     r2, r3          # compare number with bit
        bra pl  sq32_L2         # exit loop if number >= bit
        asr     r3,r3,2         # shift bit 2 places right
sq32_L2:
        zloop   sq32_endloop
        cmp     r3,0            # is R3 zero ?
        ret z   r14             # Yes ? then exit
        add     r0,r1,r3        # Trial subtract r2 -= Res + bit
        asr     r1,r1,1         # shift result right
        cmp     r2,r0
#ifdef PRED_INSTR
        subif pl r2,r0        # if >=0  do subtraction ...
        addif pl r1,r3        # .. and add bit
#else
        bra mi  sq32_L3         # if >0 then skip ahead
        sub     r2,r2,r0        # else do subtraction ...
        add     r1,r1,r3        # .. and add bit
#endif
sq32_L3:
        asr     r3,r3,2
sq32_endloop:

#else
sqrt32:
        mov     r2, r1          # move number to root into r2
        movi    r1,0            # zero result
        bset    r3, r1, 30      # set bit to 0x40000000
sq32_L1:
        cmp     r2, r3          # compare number with bit
        bra pl  sq32_L2         # exit loop if number >= bit
        asr     r3,r3,2         # shift bit 2 places right
        bra     sq32_L1

sq32_L2:
        cmp     r3,0            # is R3 zero ?
        ret z   r14             # Yes ? then exit
        add     r0,r1,r3        # Trial subtract r2 -= Res + bit
        asr     r1,r1,1         # shift result right
        cmp     r2,r0
#ifdef PRED_INSTR
        subif pl r2,r0        # if >=0  do subtraction ...
        addif pl r1,r3        # .. and add bit
#else
        bra mi  sq32_L2A         # if <0 then need skip ahead
        sub     r2,r2,r0        # else do subtraction ...
        add     r1,r1,r3        # .. and add bit
#endif
sq32_L2A:
        asr     r3,r3,2
        bra     sq32_L2
sq32_L3:
        add     r2,r2,r0        # restore r2 (add res + bit back)
        asr     r1,r1,1         # shift result right
        asr     r3,r3,2
        bra     sq32_L2
#endif
	;; -----------------------------------------------------------------
	;;
	;; udiv32 (udiv16)
	;;
	;; Divide 32(16) bit N by 32(16) bit D and return integer dividend and remainder
	;;
	;; Entry
	;; - R1 holds N (in lower 16b for udiv 16)
	;; - R2 holds D
	;; - R14 holds return address
	;;
	;; Exit
	;; - R1 holds Quotient
	;; - R2 holds remainder
	;; - C = 0 if successful ; C = 1 if divide by zero
	;; - R3,R0 used as workspace and trashed
	;; - all other registers preserved
	;;
	;; Register Usage
        ;; - R0 = temporary var
	;; - R1 = N:Quotient (N shifts out of LHS/Q in from RHS)
	;; - R2 = Divisor
	;; - R3 = Remainder
	;; - R4 = loop counter
	;; -----------------------------------------------------------------
	;;
	;; For 16b operation, N must be moved to the upper 16 bits of R1 to
	;; start so that left shifts immediately move valid bits into the carry.
	;;
	;; Routine returns on divide by zero with carry flag set.
	;;
	;; ------------------------------------------------------------------

MACRO  DIVSTEP ( )
	asl     r1, r1, 1       ; left shift N with MSB exiting into carry
	rol     r2, r2, 1       ; left shift R and import carry into LSB
	cmp     r2, r3          ; compare R with D
#ifdef PRED_INSTR
	subif pl r2, r3         ; if >= 0 then do subtract for real
	addif pl r1, 1          ; ..and increment quotient
#else
	bra  mi @next           ; skip ahead if negative ..
	sub     r2, r2, r3      ; ..otherwise do subtract for real..
	add     r1, r1, 1       ; ..and increment quotient
#endif
@next:
ENDMACRO

udiv32:
udiv1632:
udiv_0:
	mov     r3, r2         ; copy D to R3 and check != 0
	ret  z  r14            ; bail out if zero (and carry will be set also)
	movi    r2,0           ; Initialise R
        sub     r1, r1, 0      ; check if N == 0
        bra  z  udiv_end       ; bail out with Q=0,R=0 and setting C=0

        ;; Find the highest bit set in N to reduce iterations through the loop
        movi    r4, 32          ; 32 iterations
udiv_p0:
#ifdef SHIFT_32
        lsr     r0,r1,16        ; trial shift right by 16 places to lose lsbs
#else
        lsr     r0,r1,15        ; trial shift right by 15 places to lose lsbs
#endif
        bra  nz udiv_p1         ; if non zero skip ahead - bits in the top half set
#ifdef SHIFT_32        
        asl     r1,r1,16        ; else shift N left
        sub     r4,r4,16        
#else        
        asl     r1,r1,15         ; else shift N left
        sub     r4,r4,15        
#endif

udiv_p1:
#ifdef SHIFT_32        
        lsr     r0,r1,24        ; trial shift right by 24 places to lose last byte
#else
        lsr     r0,r1,15        ; trial shift right by 24 places to lose last byte
        lsr     r0,r0,9
#endif
        bra  nz udiv_p2         ; if non zero skip ahead - bits in the top half set
        sub     r4,r4,8
        asl     r1,r1,8         ; else shift N left

udiv_p2:
        or      r1, r1, r1      ; set sign bit of N
#ifdef ZLOOP_INSTR
        zloop   udiv_p4
        bra mi  udiv_p4         ; break out if top bit is set
        sub     r4, r4, 1       ; decrement loop counter
        asl     r1, r1, 1       ; shift N left
#else
udiv_p3:
        bra mi  udiv_p4          ; break out if top bit is set
        sub     r4, r4, 1       ; decrement loop counter
        asl     r1, r1, 1       ; shift N left
        bra     udiv_p3
#endif

udiv_p4:
#ifdef ZLOOP_INSTR
        zloop udiv_end
        DIVSTEP ()
        DJZ     (r4,udiv_end)   ; breakout if zero
#else
        DIVSTEP ()
        DJNZ    (r4,udiv_p4)     ; Loop again if not zero
#endif

udiv_end:
	and     r0,r0,r0        ; clear carry
	ret     r14

        ; -----------------------------------------------------------------
        ;
        ; qmul32
        ;
        ; Quick multiply 2 32 bit numbers and return a 32 bit number  without
        ; checking for overflow conditions
        ;
        ; Entry
        ; - R1 holds A
        ; - R2 holds B
        ; - R14 holds return address
        ;
        ; Exit
        ; - R1 holds product of A and B
        ; - R0 used as workspace and trashed
        ; - all other registers preserved
        ;
        ; Register Usage
        ; - R1 = Product Register
        ; - R0 = holds first shifted copy of A
        ; ------------------------------------------------------------------
qmul32:
qmul32b:
        lsr      r0, r1, 1       ; shift A into r0
        mov      r1, 0           ; initialise product (preserve C)
#ifdef ZLOOP_INSTR
qm32_loopstart:
        zloop    qm32_loopend
#ifdef PRED_INSTR
        addif c  r1, r2          ; add B into acc if carry
#else
        bra  nc  qm32_2b
        add      r1, r1, r2      ; add B into acc if carry
#endif
qm32_2b:
        asl      r2, r2, 1       ; multiply B x 2
        lsr      r0, r0, 1       ; shift A to check LSB
        bra  z   qm32_loopend    ; if A is zero then exit else loop again (preserving carry)
qm32_loopend:
        ret  nc  r14             ; return if no carry
        add      r1, r1, r2      ; Add last copy of multiplicand into acc if carry was set
        ret      r14             ; return
#else
qm32_1b:
#ifdef PRED_INSTR
        addif c  r1, r2          ; add B into acc if carry
#else
        bra  nc  qm32_2b
        add      r1, r1, r2      ; add B into acc if carry
#endif
qm32_2b:
        asl      r2, r2, 1       ; multiply B x 2
        lsr      r0, r0, 1       ; shift A to check LSB
        bra  nz  qm32_1b         ; if A is zero then exit else loop again (preserving carry)
        ret  nc  r14             ; return if no carry
        add      r1, r1, r2      ; Add last copy of multiplicand into acc if carry was set
        ret      r14             ; return
#endif
