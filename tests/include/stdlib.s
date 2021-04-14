
        ;; memcmp
        ;;
        ;; Compares the first num bytes of the block of memory pointed by ptr1 to the first num bytes pointed by ptr2,
        ;; returning zero if they all match or a value different from zero representing which is greater if they do not.
        ;;
        ;; Entry
        ;; - r1 = start address of first block
        ;; - r2 = start address of second block
        ;; - r3 = number of words to check
        ;;
        ;; Exit
        ;; - r0 workspace
        ;; - r1 = 0 if blocks match, otherwise comparison data of first mismatch
        ;; - r2-r4 trashed, all other registers preserved
        ;;

memcmp:
        PUSH    (r5)
        cmp     r3, 0
        bra z   memcmp2        ; exit with r1 = 0 if 0 bytes specified
#ifdef ZLOOP_INSTR
        zloop   memcmp1
        ld      r0, r1
        ld      r4, r2
        cmp     r0, r4
        bra  nz memcmp2
        add     r1, r1, 1
        add     r2, r2, 1
        DJZ     (r3, memcmp1)
memcmp1:
#else
memcmp1:
        ld      r0, r1
        ld      r4, r2
        cmp     r0, r4
        bra  nz memcmp3
        add     r1, r1, 1
        add     r2, r2, 1
        DJNZ    (r3, memcmp1)
#endif
memcmp2:
        mov     r0, r4          ; if falling through then ensure last data is a match
memcmp3:
        sub     r1, r0, r4      ; return the last data
        POP     (r5)
        ret

        ;; memcpy
        ;;
        ;; Entry
        ;; - r1 = start address of data to be copied
        ;; - r2 = start address of destination
        ;; - r3 = number of words to copy
        ;;
        ;; Exit
        ;; - r0 workspace
        ;; - r1,r2 point to end of source and destination areas
        ;; - r3 = 0
        ;; - all other registers preserved
        ;;

memcpy:
        cmp     r3, 0
        ret z   r14
#ifdef ZLOOP_INSTR
        zloop   memcpy1
        ld      r0, r1
        sto     r0, r2
        add     r1, r1, 1
        add     r2, r2, 1
        DJZ     (r3, memcpy1)
memcpy1:
#else
memcpy1:
        ld      r0, r1
        sto     r0, r2
        add     r1, r1, 1
        add     r2, r2, 1
        DJNZ    (r3, memcpy1)
#endif
        ret

        ;; memset
        ;;
        ;; Fill all words of specified memory block with a value
        ;;
        ;; Entry
        ;; - r1 = start address of memory block
        ;; - r2 = value to be written
        ;; - r3 = number of words in memory block
        ;;
        ;; Exit
        ;; - r0 workspace
        ;; - r1,r2 point to end of source and destination areas
        ;; - r3 = 0
        ;; - all other registers preserved
        ;;
memset:
        cmp     r3, 0
        ret z   r14
#ifdef ZLOOP_INSTR
        zloop   memset1
        sto     r2, r1
        add     r1, r1, 1
        DJZ     (r3, memset1)
memset1:
#else
memset1:
        ld      r0, r1
        sto     r2, r1
        add     r1, r1, 1
        DJNZ    (r3, memset1)
#endif
        ret
