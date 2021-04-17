

        ;; bstring.s
        ;;
        ;;  C-like library routines for working on byte strings terminated with a nul character.
        ;;
        ;; NB ALL byte strings are aligned to word boundaries and padded out to full words with zeroes.
        ;;
        ;; bstrcmp( r1, r2 ) - r1 returns zero for a match, +ve for r1>r2, -ve for r2>r1
        ;; bstrcpy( r1, r2 ) - r1 returns pointer to copied string
        ;; bstrlen( r1 )     - r1 returns length of string excl. NUL terminator

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
