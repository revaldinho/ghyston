
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
