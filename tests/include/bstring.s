

        ;; bstring.s
        ;;
        ;;  C-like library routines for working on byte strings terminated with a nul character.
        ;;
        ;; NB ALL byte strings are aligned to word boundaries and padded out to full words with zeroes.
        ;;
        ;; bstrcmp( r1, r2 ) - r1 returns zero for a match, +ve for r1>r2, -ve for r2>r1
        ;; bstrcpy( r1, r2 ) - r1 returns pointer to copied string
        ;; bstrlen( r1 )     - r1 returns length of string excl. NUL terminator


        ;; getbstrbyte
        ;;
        ;; Return the Nth byte value in a BSTRING or -1 if N > string length
        ;;
        ;; Entry
        ;; - r1 string pointer (word value)
        ;; - r2 N
        ;;
        ;; Exit
        ;; - r1 byte value or -1 if N > string length
        ;; - r0, r2-r4 used as workspace and trashed

getbstrbyte:
        PUSH    (r6)
        PUSH    (r5)
        mov     r3, r1          ; move pointer to r3
        mov     r1, 0
        sub     r1, r1, 1       ; default result is -1
        mov     r6, 0           ; byte counter
gbstrbyte0:
        ld      r5, r3          ; get word
        mov     r4, 4           ; counter for 4 bytes per word
gbstrbyte1:
        and     r0, r5, 0xFF    ; isolate the lowest byte
        bra z   gbstrbyte4      ; exit if zero
        cmp     r6, r2          ; is this the Nth byte
        bra z   gbstrbyte3      ; if yes, exit copying byte to r1
        add     r6, r6, 1       ; else add one to the byte counter
        lsr     r5, r5, 8       ; shift word down one byte
        DJNZ    (r4, gbstrbyte1); loop again if more bytes in the word
gbstrbyte2:
        add     r3, r3, 1       ; increment source pointer
        bra     gbstrbyte0      ; next word

gbstrbyte3:                     ; this is the Nth byte
        mov     r1, r0          ; so copy into r1 to return
gbstrbyte4:                     ; all done, return length in r1
        POP     (r5)
        POP     (r6)
        ret     r14

        ;; putbstrbyte
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
putbstrbyte:
        PUSH    (r5)
        mov     r5, r3          ; save value to be merged in
        mov     r4, 0x0FF       ; setup data mask
        lsr     r0, r2, 2       ; shift byte counter 2 places to make word destination
        add     r1, r1, r0      ; add string pointer base and N to make word counter
        and     r2, r2, 0x03    ; make r2 now a byte counter within the word by using only the LSBs
        ld      r0, r1          ; read the existing word data
        mov     r3, 0           ; byte index
pbstrbyte0:
        cmp     r2, r3          ; does byte index match byte address
        bra nz  pbstrbyte1      ; if not, next byte
        movi    r2, 0xFFFF      ; get inverted data mask into r2
        movti   r2, 0xFFFF
        xor     r2, r2, r4
        and     r0, r0, r2      ; blank out byte in existing data by anding with NOT mask
        and     r5, r5, r4      ; ensure incoming data is only one byte by anding with mask
        or      r0, r0, r5      ; merge data together
        sto     r0, r1          ; write it back
        POP     (r5)
        ret     r14             ; and exit
pbstrbyte1:
        asl     r4, r4, 8       ; shift byte mask data
        asl     r5, r5, 8       ; shift byte data
        add     r3, r3, 1       ; increment byte index
        bra     pbstrbyte0      ; and loop again

;;         ;; --------------------------------------------------------------------------------------------
;;         ;; bstrcat
;;         ;; --------------------------------------------------------------------------------------------
;;         ;;
;;         ;; Concatenate two strings by copying the second (source) string onto the end of the first (dest).
;;         ;;
;;         ;; Entry
;;         ;; - r1 dest string pointer
;;         ;; - r2 source string pointer
;;         ;;
;;         ;; Exit
;;         ;; - r1 = 0
;;         ;; - r0,r2-r4 used as workspace and trashed
;;         ;; - all other registers preserved
;;         ;; --------------------------------------------------------------------------------------------
;;
;; bstrcat:
;;         PUSH    (r7)            ; preserve higher registers
;;         PUSH    (r6)
;;         PUSH    (r5)
;;         PUSH    (r2)
;;         PUSH    (r1)
;;
;;         ;; Find the end of the first string
;;
;;         mov     r3, r1          ; move pointer to r3
;;         mov     r1, 0           ; zero result
;; bstrcat0:
;;         mov     r0, 0x0FF       ; byte mask set for low byte
;;         ld      r6, r3          ; get word
;;         mov     r5, 4           ; counter for 4 bytes per word
;; bstrcat1:
;;         and     r4, r6, r0      ; isolate the lowest byte
;;         bra z   bstrlen3        ; exit if zero
;;         asl     r0, r0, 8       ; shift byte mask to next byte
;;         DJNZ    (r5, bstrcat1)  ; loop again if more bytes in the word
;;
;; bstrcat2:
;;         add     r3, r3, 1       ; increment source pointer
;;         bra     bstrcat0        ; next word
;;
;; bstrcat3:
;;         ;; at this point r3 is pointing to the last word of str1
;;         ;; and the mask r0 is set at the current byte
;;         ;; and r5 = 4 (low byte) .. 1 (highest byte)
;;         mov     r4, 4
;;         sub     r5, r4, r5      ; change r5 to hold 0 (low byte) .. 3 (high byte)
;;
;; bstrcat4:
;;         mov     r7, 0xFF        ; byte mask set for low byte of str2
;;         ld      r6, r2          ; get str2 word
;;         mov     r5, 4           ; counter for 4 bytes per word
;; bstrcat5:
;;         and     r4, r6,r7       ; isolate low byte str2
;;         bra  z  bstrcat6        ; exit if zero
;;         ;; non-zero so need to add it into the new word by shifting into place
;;
;;
;;
;;
;;
;;         asl     r7, r7, 8       ; shift byte mask to next byte
;;         DJNZ    (r5, bstrcat5)  ; loop again if more bytes in the word
;; bstrcat5:
;;         add     r2, r2, 1       ; increment source pointer
;;         bra     bstrcat4        ; next word
;;
;;
;; bstrcat6:
;;         ;;  need to zero the last byte
;;
;;
;; bstrcat7:                       ; all done, return length in r1
;;         POP     (r5)
;;         ret     r14
        ;; --------------------------------------------------------------------------------------------
        ;; bstrcmp
        ;; --------------------------------------------------------------------------------------------
        ;;
        ;; Compare two strings returning zero if they match or a positive number of the first string is
        ;; greater than the second.
        ;;
        ;; Entry
        ;; - r1 source string pointer
        ;; - r2 dest string pointer
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
        ;; - r1 source string pointer
        ;; - r2 dest string pointer
        ;;
        ;; Exit
        ;; - r1 dest string pointer
        ;; - r0,r2-r4 used as workspace and trashed
        ;; - all other registers preserved
        ;; --------------------------------------------------------------------------------------------

bstrcpy:
        PUSH    (r2)            ; save pointer to destination string
        PUSH    (r6)
        PUSH    (r5)

bstrcpy0:
        mov     r0, 0x0FF       ; byte mask set for low byte
        ld      r3, r1          ; get word
        mov     r4, 0           ; zero r4 to start
        mov     r6, 4           ; counter for 4 bytes per word

#ifdef ZLOOP_INSTR
        zloop bstrcpy2
#endif
bstrcpy1:
        and     r5, r3, r0      ; isolate the byte
        bra z   bstrcpy3        ; exit if zero
        or      r4, r4, r5      ; else OR it into the current word
        asl     r0, r0, 8       ; shift byte mask to next byte
#ifdef ZLOOP_INSTR
        DJZ     (r6, bstrcpy2)  ; breakout if no more bytes in the word
#else
        DJNZ    (r6, bstrcpy1)  ; loop again if more bytes in the word
#endif
bstrcpy2:
        sto     r4, r2          ; save the word
        add     r1, r1, 1       ; increment source pointer
        add     r2, r2, 1       ; increment dest pointer
        bra     bstrcpy0

bstrcpy3:
        sto     r4, r2
        POP     (r5)
        POP     (r6)
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
        PUSH    (r5)
        mov     r3, r1          ; move pointer to r3
        mov     r1, 0           ; zero result
bstrlen0:
        mov     r0, 0x0FF       ; byte mask set for low byte
        ld      r2, r3          ; get word
        mov     r5, 4           ; counter for 4 bytes per word
#ifdef ZLOOP_INSTR
        zloop bstrlen2
#endif
bstrlen1:
        and     r4, r2, r0      ; isolate the lowest byte
        bra z   bstrlen3        ; exit if zero
        add     r1, r1, 1       ; else add one to the length
        asl     r0, r0, 8       ; shift byte mask to next byte
#ifdef ZLOOP_INSTR
        DJZ     (r5, bstrlen2)  ; breakout if no more bytes in the word
#else
        DJNZ    (r5, bstrlen1)  ; loop again if more bytes in the word
#endif
bstrlen2:
        add     r3, r3, 1       ; increment source pointer
        bra     bstrlen0        ; next word

bstrlen3:                       ; all done, return length in r1
        POP     (r5)
        ret     r14
