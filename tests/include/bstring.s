        ;; bstring.s
        ;;
        ;;  C-like library routines for working on byte strings terminated with a nul character.
        ;;
        ;; NB ALL byte strings are aligned to word boundaries and padded out to full words with zeroes.

        ;; --------------------------------------------------------------------------------------------
        ;; getbstrbyte
        ;; --------------------------------------------------------------------------------------------
        ;;
        ;; Return the Nth byte value in a BSTRING without any checking for exceeding the length of the 
        ;; string
        ;; 
        ;; Entry
        ;; - r1 string pointer (word value)
        ;; - r2 N
        ;;
        ;; Exit
        ;; - r1 byte value or 0 if N > string length
        ;; - r0, r2-r4 used as workspace and trashed
        ;; --------------------------------------------------------------------------------------------
getbstrbyte:
        lsr     r3, r2, 2       ; get word pointer for N
        add     r1, r1, r3      ; add to string base
        ld      r3, r1          ; get the word holding the byte
        and     r2, r2, 0x03    ; LSBs of r2 point at the byte within the word
        bra  z  gbstrbyte1
        lsr     r3, r3, 8       ; shift word 1 byte to right
        cmp     r2, 1
        bra  z  gbstrbyte1
        lsr     r3, r3, 8       ; shift word 1 byte to right
        cmp     r2, 2
        bra  z  gbstrbyte1
        lsr     r3, r3, 8       ; shift word 1 byte to right
gbstrbyte1:
        and     r1, r3, 0x0FF   ; mask data with low bye
        ret     r14

        ;; --------------------------------------------------------------------------------------------
        ;; putbstrbyte
        ;; --------------------------------------------------------------------------------------------
        ;;
        ;; Put a character into the Nth byte of a BSTRING but with no checking whether the string length is
        ;; exceeded. Use with care.
        ;;
        ;; Entry
        ;; - r1 dest string pointer
        ;; - r2 N
        ;; - r3 character to be inserted
        ;;
        ;; Exit
        ;; - r0-r4 used as workspace and trashed
        ;; --------------------------------------------------------------------------------------------
putbstrbyte:
        PUSH    (r5)
        mov     r5, r3          ; save value to be merged in
        mov     r4, 0x0FF       ; setup data mask
        lsr     r0, r2, 2       ; shift byte counter 2 places to make word destination
        add     r1, r1, r0      ; add string pointer base and N to make word counter
        and     r2, r2, 0x03    ; make r2 now a byte counter within the word by using only the LSBs
        ld      r0, r1          ; read the existing word data
        mov     r3, 0           ; byte index

#ifdef ZLOOP_INSTR
        zloop   pbstrbyte1
#endif
pbstrbyte0:
        cmp     r2, r3          ; does byte index match byte address
        bra z   pbstrbyte1      ; if yes, bail out
        asl     r4, r4, 8       ; shift byte mask data
        asl     r5, r5, 8       ; shift byte data
        add     r3, r3, 1       ; increment byte index
#ifndef ZLOOP_INSTR
        bra     pbstrbyte0      ; and loop again
#endif

pbstrbyte1:        
        xor     r2, r4, -1      ; invert mask by XORing with (sign extended) 0xFFFFFFFF
        and     r0, r0, r2      ; blank out byte in existing data by anding with NOT mask
        and     r5, r5, r4      ; ensure incoming data is only one byte by anding with mask
        or      r0, r0, r5      ; merge data together
        sto     r0, r1          ; write it back
        POP     (r5)
        ret     r14             ; and exit


        ;; --------------------------------------------------------------------------------------------
        ;; bstrcat
        ;; --------------------------------------------------------------------------------------------
        ;;
        ;; Concatenate a source string onto the end of a destination string. The start of both strings
        ;; is word aligned, but the end of the destination string might not be.
        ;;
        ;; If the end of the destination string is word aligned, then a fast word copy is done. Otherwise
        ;; the routine needs to do a slower byte by byte copy.
        ;;
        ;; Entry
        ;; - r1 dest string pointer (word aligned)
        ;; - r2 source string pointer (word aligned)
        ;;
        ;; Exit
        ;; - r1 result
        ;; - r0,r2-r4 used as workspace and trashed
        ;; - all other registers preserved
        ;; --------------------------------------------------------------------------------------------
	;;
	;;        l = strlen(r1)
	;;        # if the destination is word aligned then do a simple string copy to a word address
	;;        if ( l & 0x03 ==0 ) :
	;;            bstrcpy r2, r1 + (l>>2)
	;;        else:
	;;            for i=0 to strlen(r2)
	;;               b = getbyte(r2, i)
	;;               putbyte (r1, i + l, b)


bstrcat:
        PUSH    (r14)           ; save return address
        PUSH    (r1)            ; save dest addr
        PUSH    (r2)            ; save source addr

        jsr     bstrlen         ; r1 = strlen (bytes)
        POP     (r2)            ; r2 = source str
        POP     (r3)            ; r3 = dest str
        and     r0, r1, 0x3     ; check LSBs of dest str length
        bra z   bstrcat1        ; if zero, then all word aligned

        ;;  else need to copy byte by byte
        PUSH    (r10)
        PUSH    (r9)
        PUSH    (r8)
        PUSH    (r7)
        PUSH    (r6)

        mov     r9, r3          ; save dest str pointer in r9
        mov     r10, r1         ; save dest str length in r10
        mov     r8, r2          ; save source str pointer in r8

        mov     r1, r2          ; move source str pointer to r1
        jsr     bstrlen         ; get length of source string
        mov     r7, r1          ; save source str length in r7

        mov     r6, 0           ; counter
bstrcat2:
        mov     r1,r8           ; restore pointer to source string
        mov     r2,r6           ; move byte counter to r2
        jsr     getbstrbyte     ; get the source byte in r1
        mov     r3, r1          ; transfer to r3
        mov     r1, r9          ; restore pointer to dest string
        add     r2, r10,r6      ; byte location = dest strlen + counter
        jsr     putbstrbyte
        cmp     r6, r7          ; reached the end of the source string? (including last zero byte)
        bra  z  bstrcat3        ; if yes, then exit
        add     r6, r6, 1       ; else next byte
        bra     bstrcat2
bstrcat3:
        POP     (r6)
        POP     (r7)
        POP     (r8)
        POP     (r9)
        POP     (r10)
        POP     (r14)
        ret     r14

bstrcat1:                       ; Fast word aligned copy
        lsr     r1, r1, 2       ; make strlen into a word length
        add     r1, r1, r3      ; add to original dest pointer
        jsr     bstrcpy         ; standard word aligned copy and then return
        POP     (r14)
        ret     r14

        ;; --------------------------------------------------------------------------------------------
        ;; bstrcmp
        ;; --------------------------------------------------------------------------------------------
        ;;
        ;; Compare two strings returning zero if they match or a positive number of the first string is
        ;; greater than the second.
        ;;
        ;; Entry
        ;; - r1 string pointer (word aligned)
        ;; - r2 string pointer (word aligned)
        ;;
        ;; Exit
        ;; - r1 result
        ;; - r0,r2-r4 used as workspace and trashed
        ;; - all other registers preserved
        ;; --------------------------------------------------------------------------------------------

bstrcmp:
        PUSH    (r7)            ; preserve higher registers
        PUSH    (r6)
        PUSH    (r5)

bstrcmp0:
        ld      r3, r1          ; get word A
        ld      r4, r2          ; get word B
        mov     r7, 4           ; 4 bytes to check
#ifdef ZLOOP_INSTR
        zloop bstrcmp2
#endif
bstrcmp1:
        and     r5, r3, 0x0FF   ; isolate byte A
        and     r6, r4, 0x0FF   ; isolate byte B
        sub     r5, r5, r6      ; get difference between bytes
        bra nz  bstrcmp3        ; bail out if non zero
        cmp     r6, 0           ; otherwise check if one string (and therefore both) is NUL
        bra z   bstrcmp3        ; and bail out with zero result, ie success
        lsr     r3, r3, 8       ; shift words right for next comparison
        lsr     r4, r4, 8
#ifdef ZLOOP_INSTR
        DJZ    (r7, bstrcmp2)   ; breakout if byte counter is zero
#else
        DJNZ    (r7, bstrcmp1)  ; next byte
#endif

bstrcmp2:
        add     r1, r1, 1       ; update pointers
        add     r2, r2, 1
        bra     bstrcmp0        ; loop again to next word

bstrcmp3:
        mov     r1, r5          ; return result in r1
        POP     (r5)
        POP     (r6)
        POP     (r7)
        ret     r14

        ;; --------------------------------------------------------------------------------------------
        ;; bstrcpy
        ;; --------------------------------------------------------------------------------------------
        ;;
        ;; Copy a byte string from source pointer to destination pointer, returning the start
        ;; address of the copied string
        ;;
        ;; Entry
        ;; - r1 dest string pointer
        ;; - r2 source string pointer
        ;;
        ;; Exit
        ;; - r1 dest string pointer
        ;; - r0,r2-r4 used as workspace and trashed
        ;; - all other registers preserved
        ;; --------------------------------------------------------------------------------------------

bstrcpy:
        PUSH    (r1)            ; save pointer to destination string
        PUSH    (r5)

#ifdef ZLOOP_INSTR
        zloop   bstrcpy1
#endif
bstrcpy0:
        mov     r0, 0x0FF       ; byte mask set for low byte
        ld      r3, r2          ; get word from source
        mov     r4, 0           ; zero r4 to start
        and     r5, r3, r0      ; isolate the byte
        bra z   bstrcpy1        ; exit if zero
        or      r4, r4, r5      ; else OR it into the current word
        asl     r0, r0, 8       ; shift byte mask to next byte
        and     r5, r3, r0      ; isolate the byte
        bra z   bstrcpy1        ; exit if zero
        or      r4, r4, r5      ; else OR it into the current word
        asl     r0, r0, 8       ; shift byte mask to next byte
        and     r5, r3, r0      ; isolate the byte
        bra z   bstrcpy1        ; exit if zero
        or      r4, r4, r5      ; else OR it into the current word
        asl     r0, r0, 8       ; shift byte mask to next byte
        and     r5, r3, r0      ; isolate the byte
        bra z   bstrcpy1        ; exit if zero
        or      r4, r4, r5      ; else OR it into the current word

        sto     r4, r1          ; save the word
        add     r2, r2, 1       ; increment source pointer
        add     r1, r1, 1       ; increment dest pointer
#ifndef ZLOOP_INSTR
        bra     bstrcpy0
#endif
bstrcpy1:
        sto     r4, r1
        POP     (r5)
        POP     (r1)            ; return pointer to copied string
        ret     r14

        ;; --------------------------------------------------------------------------------------------
        ;; bstrlen
        ;; --------------------------------------------------------------------------------------------
        ;;
        ;; Return the length of a string in bytes excluding the NUL terminator.
        ;;
        ;; Entry
        ;; - r1 source string pointer
        ;;
        ;; Exit
        ;; - r1 string length
        ;; - r0,r2-r4 used as workspace and trashed
        ;; - all other registers preserved
        ;; --------------------------------------------------------------------------------------------
bstrlen:
        PUSH    (r1)            ; save original pointer
        mov     r3, 0           ; zero result

#ifdef ZERO_INSTR
        zloop   bstrlen3
#endif
bstrlen_loop:
        mov     r0, 0x0FF       ; byte mask set for low byte
        ld      r2, r1          ; get word
        and     r4, r2, r0      ; isolate the lowest byte
        bra z   bstrlen0        ; exit if zero
        asl     r0, r0, 8       ; shift byte mask to next byte
        and     r4, r2, r0      ; isolate the lowest byte
        bra z   bstrlen1        ; exit if zero
        asl     r0, r0, 8       ; shift byte mask to next byte
        and     r4, r2, r0      ; isolate the lowest byte
        bra z   bstrlen2        ; exit if zero
        asl     r0, r0, 8       ; shift byte mask to next byte
        and     r4, r2, r0      ; isolate the lowest byte
        bra z   bstrlen3        ; exit if zero
        add     r1, r1, 1       ; increment source pointer
#ifndef ZERO_INSTR
        bra     bstrlen_loop    ; next word
#endif
bstrlen3:
        add     r3, r3, 1       ; byte 3
bstrlen2:
        add     r3, r3, 1       ; byte 2
bstrlen1:
        add     r3, r3, 1       ; byte 1
bstrlen0:                       ; byte 0
        POP     (r2)            ; get original word pointer
        sub     r1, r1, r2      ; subtract from current word pointer
        asl     r1, r1, 2       ; multiply by 4 to get byte pointer
        add     r1, r1, r3      ; add to intra word byte counter
                                ; all done, return length in r1
        ret     r14
