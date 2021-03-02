        ;;
        ;; Program to generate Pi using the Spigot Algorithm from
        ;;
        ;; http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
        ;;      
        ;; Full 32b version, with collect-9s algorithm for correcting pre-digit overflow
        ;;
        ;; Translated from the OPC7 version.

        ;; define this to optimize for hardware multiplier but limited to 18x18 operation
#define MUL18X18 1
        ;; #define UNROLL_UDIV2 1
#define UNROLL_UDIV4 1

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
ENDMACRO

        ; Register Map
        ; (r15  = PC)
        ; r14   = stack pointer
        ; r13   = link register
        ; r12   = inner loop counter
        ; r11   = Q (Result)
        ; r10   = denominator
        ; r9    = outer loop counter
        ; r8    = predigit
        ; r7    = remainder pointer
        ; r6    = nines counter
        ; r5    = c
        ; r3,r4 = local registers
        ; r1,r2 = temporary registers, parameters and return registers
        ; (r0   =0)

        EQU     digits,   16          ; 16
        EQU     cols,     1+(digits*10//3)            ; 1 + (digits * 10/3)

        mov     r13,r0                ; Initialise r13 to stop PUSH/POP ever loading Xs to stack for regression runs
        mov     r14, 0x0FFE           ; Set stack to grow down from here for monitor
        mov     r0, output_data       ; setup a variable to point to the output data area
        sto.w   r0, output_ptr

        jmp     start                ; Program start at 0x1000 for use with monitor/copro

        ORG     0x100
start:
        mov     r8,0
        mov     r4,0
        mov     r5,0                 ; zero C

        ;; trivial banner
        WRCH    (0x4f)
        WRCH    (0x6b)
        WRCH    (0x20)

        mov     r6,0                    ; zero nines counter
                                        ; Initialise remainder/denominator array using temp vars
        mov     r2,2                    ; r2=const 2 for initialisation, used as data for rem[] and increment val
        mov     r3,cols+remain-1        ; loop counter i starts at index = 1
L1:     sto.w   r2,r3                   ; store remainder value to pointer
        sub     r3, r3, 1               ; next loop counter
        cmp     r3, remain-1
        bra nz  L1

        mov     r9,digits               ; set up outer loop counter (digits)
L3:     mov     r11,0                   ; r11 = Q
        ;
        ; All loop counters count down from
        ; RHS of the arrays in this loop
        ;
        mov     r12,cols-1              ; r4 inner loop counter
        mov     r7,remain+cols-1
        mov     r10,(cols-1)*2 + 1      ; initial denominator at furthest column + 2 (pre decrement before use)

L4:     ld.w    r2,r7                   ; r2 <- *remptr = r[i]

#ifdef MUL18X18
        mul     r1, r2, 10
#else
        asl     r1, r2, 1               ; Compute 16b result for r[i] * 10
        asl     r2, r2, 3
        add     r1,r1,r2
#endif
        sub     r10, r10, 2             ; next denominator        
        add     r1,r11,r1               ; Q <- Q + (r[i]*10)
        mov     r2,r10
        jsr     udiv32                  ; Compute Q % denom, Q // denom
        mov     r11,r1                  ; Q<- Quotient
        sto.w   r2, r7                  ; rem[i] <- r2
        sub     r7, r7, 1               ; dec remptr
        sub     r12, r12, 1             ; decr loop counter
        bra  z  L10                     ; break out if zero

#ifdef MUL18X18        
        mul     r11, r11, r12           ; Q <- Q * i
#else 
        mov     r2, r12                 ; Q <- Q * i
        mov     r1, r11
        jsr     qmul32b
        mov     r11,r1
#endif
        bra     L4                      ; loop again

L10:    mov     r1,r11                  ; result (Q) = C + Q//10
        mov     r2,10
        jsr     udiv32
        add     r11,r1,r5               ; result (Q) = quotient + C
        mov     r5,r2                   ; (new) C = remainder from division

        cmp     r11,9                   ; Is result a 9 ?
        bra nz  L4b                     ; No, move on
        add     r6, r6, 1               ; Yes, increment 9s counter
        bra     SDCL6                   ; and continue with loop

L4b:    cmp     r11,10                  ; Is result 10 and needing correction?
        bra nz  SDCL5                   ; if no correction needed then continue else start corrections
        add     r8, r8, 1               ; increment predigit
        mov     r11,0                   ; Zero result
        WRDIG   (r8)                    ; write predigit as ASCII
        cmp     r6, 0        
        bsr  nz PRINTZEROES             ; Now write out any nines as 0s
        bra     SDCL6b

SDCL5:  cmp     r9,digits
        bra z   SDCL6a                  ; if first digit nothing to print yet
SDCL8:  WRDIG   (r8)                    ; write predigit as ASCII
        cmp     r6, 0
        bsr  nz PRINTNINES              ; Now write out any nines

SDCL6a: cmp     r9,digits-1             ; Print the decimal point if this is the first digit printed
        bra nz  SDCL6b
        WRCH    (46)

SDCL6b: mov     r8,r11                  ; set predigit = Q
SDCL6:  sub     r9, r9, 1               ; dec loop counter
        bra nz  L3

SDCL7:  WRDIG    (r8)                    ; Print last predigit (ASCII) and any nines we are holding
        cmp     r6, 0
        bsr  nz PRINTNINES

L7b:
        WRCH    (10)                   ; Print Newline to finish off
        WRCH    (13)


END:    HALT ()
        bra     END

        
        ; -----------------------------------------------------------------
        ;
        ; PRINTZEROES/PRINTNINES
        ;
        ; Print a string of nines or zeroes depending on the entry point.
        ; The number of digits is given by the value in r6 on entry.
        ;
        ; Entry
        ; - R6 holds a non-zero number of digits to print
        ; - R14 holds return address
        ;
        ; Exit
        ; - R6 holds zero
        ; - R2, R1, R0 used as workspace and trashed (inc by oswrch)
        ; - all other registers preserved
        ; ------------------------------------------------------------------
PRINTZEROES:
        mov     r2, 48
        bra     PZN0
PRINTNINES:
        mov     r2, 48+9
PZN0:   mov     r3, r14         ; save return address before nested calls to oswrch        
PZN1:   mov     r1, r2
        jsr     oswrch
        sub     r6,r6,1
        ret  z  r3
        bra     PZN1
        
#ifndef MUL18X18        
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
#endif
	; -----------------------------------------------------------------
	;
	; udiv32 (udiv16)
	;
	; Divide 32(16) bit N by 32(16) bit D and return integer dividend and remainder
	;
	; Entry
	; - R1 holds N (in lower 16b for udiv 16)
	; - R2 holds D
	; - R14 holds return address
	;
	; Exit
	; - R1 holds Quotient
	; - R2 holds remainder
	; - C = 0 if successful ; C = 1 if divide by zero
	; - R3,R0 used as workspace and trashed
	; - all other registers preserved
	;
	; Register Usage
	; - R1 = N:Quotient (N shifts out of LHS/Q in from RHS)
	; - R2 = Divisor
	; - R3 = Remainder
	; - R0 = loop counter
	; -----------------------------------------------------------------
	;
	; For 16b operation, N must be moved to the upper 16 bits of R1 to
	; start so that left shifts immediately move valid bits into the carry.
	;
	; Routine returns on divide by zero with carry flag set.
	;
	; ------------------------------------------------------------------
udiv32:
	movi    r0,32           ; loop counter
	bra     udiv
udiv16:
	movi    r0,16           ; loop counter
	asl     r1, r1, 16      ; Move N into R1 upper half word/zero lower half
udiv:
	movi    r3,0           ; Initialise R
	cmp     r2,0           ; check D != 0
	ret  z  r14            ; bail out if zero (and carry will be set also)
udiv_1:
	asl     r1, r1, 1       ; left shift N with MSB exiting into carry
	rol     r3, r3, 1       ; left shift R and import carry into LSB
	cmp     r3, r2          ; compare R with D
	bra  mi udiv_2          ; skip ahead if negative ..
	sub     r3, r3, r2      ; ..otherwise do subtract for real..
	add     r1, r1, 1       ; ..and increment quotient
#ifdef UNROLL_UDIV2
udiv_2:
	asl     r1, r1, 1       ; left shift N with MSB exiting into carry
	rol     r3, r3, 1       ; left shift R and import carry into LSB
	cmp     r3, r2          ; compare R with D
	bra  mi udiv_3          ; skip ahead if negative ..
	sub     r3, r3, r2      ; ..otherwise do subtract for real..
	add     r1, r1, 1       ; ..and increment quotient
udiv_3: 
	sub     r0, r0, 2       ; dec loop counter
#else
#ifdef UNROLL_UDIV4
udiv_2:
	asl     r1, r1, 1       ; left shift N with MSB exiting into carry
	rol     r3, r3, 1       ; left shift R and import carry into LSB
	cmp     r3, r2          ; compare R with D
	bra  mi udiv_3          ; skip ahead if negative ..
	sub     r3, r3, r2      ; ..otherwise do subtract for real..
	add     r1, r1, 1       ; ..and increment quotient
udiv_3:
	asl     r1, r1, 1       ; left shift N with MSB exiting into carry
	rol     r3, r3, 1       ; left shift R and import carry into LSB
	cmp     r3, r2          ; compare R with D
	bra  mi udiv_4          ; skip ahead if negative ..
	sub     r3, r3, r2      ; ..otherwise do subtract for real..
	add     r1, r1, 1       ; ..and increment quotient
udiv_4:
	asl     r1, r1, 1       ; left shift N with MSB exiting into carry
	rol     r3, r3, 1       ; left shift R and import carry into LSB
	cmp     r3, r2          ; compare R with D
	bra  mi udiv_5          ; skip ahead if negative ..
	sub     r3, r3, r2      ; ..otherwise do subtract for real..
	add     r1, r1, 1       ; ..and increment quotient
udiv_5: 
	sub     r0, r0, 4       ; dec loop counter        
#else
udiv_2:
	sub     r0, r0, 1       ; dec loop counter
#endif
#endif        
	bra  nz udiv_1          ; repeat until zero
	and     r1, r1, r1      ; clear carry
	mov     r2, r3          ; put remainder into r2 for return
	ret     r14
        ; --------------------------------------------------------------
        ;
        ; oswrch
        ;
        ; Output a single ascii character to the uart
        ;
        ; Entry:
        ;       r1 is the character to output
        ; Exit:
        ;       r2 used as temporary
        ; ---------------------------------------------------------------
oswrch:
oswrch_loop:
        ld.w    r0, output_ptr
        sto.w   r1, r0
        add     r0, r0, 1
        sto.w   r0, output_ptr
        ret     r14


        ; DATA MEM defines
        EQU     output_ptr,              0
        EQU     output_data,             1
        EQU     remain_minus_one,        0x100
        EQU     remain,                  0x101
