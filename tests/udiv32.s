        ORG     0
	jmp     START
        
        
        
	ORG     0x100
START:
	movi   r5, RESULTS
	movi   r1, 0x0017
	movi   r2, 0x0003
	jsr     udiv32
	sto.w   r1, r5
	add     r5, r5, 4
        sto.w   r2, r5
	add     r5, r5, 4         
	movi   r1, 0x0090
	movi   r2, 0x0045
	jsr     udiv32
	sto.w   r1, r5
	add     r5, r5, 4
        sto.w   r2, r5
	add     r5, r5, 4        
END:
	bra     END
	
        
	ORG 0x0200
        
	# -----------------------------------------------------------------
	#
	# udiv32 (udiv16)
	#
	# Divide 32(16) bit N by 32(16) bit D and return integer dividend and remainder
	#
	# Entry
	# - R1 holds N (in lower 16b for udiv 16)
	# - R2 holds D
	# - R14 holds return address
	#
	# Exit
	# - R1 holds Quotient
	# - R2 holds remainder
	# - C = 0 if successful ; C = 1 if divide by zero
	# - R3,R0 used as workspace and trashed
	# - all other registers preserved
	#
	# Register Usage
	# - R1 = N:Quotient (N shifts out of LHS/Q in from RHS)
	# - R2 = Divisor
	# - R3 = Remainder
	# - R0 = loop counter
	# -----------------------------------------------------------------
	#
	# For 16b operation, N must be moved to the upper 16 bits of R1 to
	# start so that left shifts immediately move valid bits into the carry.
	#
	# Routine returns on divide by zero with carry flag set.
	#
	# ------------------------------------------------------------------
udiv32:
	movi    r0,32           # loop counter
	bra     udiv
udiv16:
	movi    r0,16           # loop counter
	asl     r1, r1, 16      # Move N into R1 upper half word/zero lower half
udiv:
	movi     r3,0           # Initialise R
	cmp      r2,0           # check D != 0
	ret  z   r14            # bail out if zero (and carry will be set also)
udiv_1:
	asl     r1, r1, 1       # left shift N with MSB exiting into carry
	rol     r3, r3, 1       # left shift R and import carry into LSB
	cmp     r3, r2          # compare R with D
	bra  mi udiv_2          # skip ahead if negative ..
	sub     r3, r3, r2      # ..otherwise do subtract for real..
	add     r1, r1, 1       # ..and increment quotient
udiv_2: 
	sub     r0, r0, 1       # dec loop counter
	bra  nz udiv_1          # repeat 'til zero
	and     r1, r1, r1      # clear carry
	mov     r2, r3          # put remainder into r2 for return
	ret     r14
	# DATA MEMORY
	ORG 0
RESULTS:
	
        
