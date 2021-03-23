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
        sub     r2,r2,r0
        bra mi  sq32_L3         # if <0 then need to restore r2
        asr     r1,r1,1         # shift result right
        add     r1,r1,r3        # .. and add bit
        asr     r3,r3,2
        bra     sq32_L2
sq32_L3:
        add     r2,r2,r0        # restore r2 (add res + bit back)
        asr     r1,r1,1         # shift result right
        asr     r3,r3,2
        bra     sq32_L2

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
	;; - R1 = N:Quotient (N shifts out of LHS/Q in from RHS)
	;; - R2 = Divisor
	;; - R3 = Remainder
	;; - R0 = loop counter
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
	bra  mi @next           ; skip ahead if negative ..
	sub     r2, r2, r3      ; ..otherwise do subtract for real..
	add     r1, r1, 1       ; ..and increment quotient
@next:
ENDMACRO

udiv32:
#ifdef NOUNROLL_UDIV
	movi    r0,32           ; loop counter
#endif
#ifdef UNROLL_UDIV2
	movi    r0,16           ; loop counter
#endif
#ifdef UNROLL_UDIV4
	movi    r0,8           ; loop counter
#endif
#ifdef UNROLL_UDIV8
	movi    r0,4           ; loop counter
#endif
        bra     udiv_0
        ;; Determine whether to use 16 or 32 bit division depending on whether
        ;; any bits in the upper half-word of either operatnd are set
udiv1632:
        or      r0, r1, r2
#ifdef SHIFT_32
        lsr     r0, r0, 16
#else
        lsr     r0, r0, 8
        lsr     r0, r0, 8
#endif
        bra  nz udiv32
udiv16:
#ifdef NOUNROLL_UDIV
	movi    r0,16           ; loop counter
#endif
#ifdef UNROLL_UDIV2
	movi    r0,8           ; loop counter
#endif
#ifdef UNROLL_UDIV4
	movi    r0,4           ; loop counter
#endif
#ifdef UNROLL_UDIV8
	movi    r0,2           ; loop counter
#endif
#ifdef SHIFT_32
	asl     r1, r1, 16      ; Move N into R1 upper half word/zero lower half
#else
        asl     r1, r1, 8
        asl     r1, r1, 8
#endif
udiv_0:
	mov     r3, r2         ; copy D to R3 and check != 0
	ret  z  r14            ; bail out if zero (and carry will be set also)
	movi    r2,0           ; Initialise R
udiv_1:
#ifdef UNROLL_UDIV2
        DIVSTEP ()
        DIVSTEP ()
#else
 #ifdef UNROLL_UDIV4
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
 #else
  #ifdef UNROLL_UDIV8
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
  #else
        DIVSTEP ()
  #endif
 #endif
#endif
        DJNZ    (r0,udiv_1)
	and     r1, r1, r1      ; clear carry
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
qmul32b:
        lsr      r0, r1, 1       ; shift A into r0
        mov      r1, 0           ; initialise product (preserve C)
qm32_1b:
        bra  nc  qm32_2b
        add      r1, r1, r2      ; add B into acc if carry
qm32_2b:
        asl      r2, r2, 1       ; multiply B x 2
        lsr      r0, r0, 1       ; shift A to check LSB
        bra  nz  qm32_1b         ; if A is zero then exit else loop again (preserving carry)
        ret  nc  r14             ; return if no carry
        add      r1, r1, r2      ; Add last copy of multiplicand into acc if carry was set
        ret      r14             ; return