        ;; Ackermann's function test
        ;;
        ;;   FOR i = 0 TO 3 DO
        ;;   { writef("a(%n, **): ", i)
        ;;     FOR j = 0 TO 6 DO
        ;;       writef(" %i8", ack(i, j))
        ;;     newline()
        ;;     newline()
        ;;   }
        ;;   RESULTIS 0
        ;;         }


#include "options.h"
#include "macros.h"

        ORG     0x00
        EQU     MAX_X, 4
        EQU     MAX_Y, 5
        movi    r12,STACK_TOP
        mov     r6, 0
loop1:
        mov     r5, 0
loop:   jsr     acktest
        add     r5,r5, 1
        cmp     r5, MAX_X
        bra nz  loop
        add     r6,r6, 1
        cmp     r6, MAX_Y
        bra nz  loop1
        HALT    ()
end:    bra end


acktest:

        PUSH    (r14)
        mov     r1, m1
        jsr     sprint
        mov     r1, r5
        jsr     printdec32
        mov     r1, 44          ; comma
        jsr     oswrch
        mov     r1, r6
        jsr     printdec32
        mov     r1, m2
        jsr     sprint
        mov     r1, r5
        mov     r2, r6
        jsr     ack
        jsr     printdec32
        PRINT_NL ()
        POP     (r14)
        ret     r14

        ;; ----------------------------------------
        ;; Ackermann's Function
        ;; ----------------------------------------
        ;; LET ack(x, y) = x=0 -> y+1,
        ;;                 y=0 -> ack(x-1, 1),
        ;;                 ack(x-1, ack(x, y-1))
        ;; ----------------------------------------
        ;; Entry:
        ;;   r1 = x
        ;;   r2 = y
        ;; Exit
        ;;   r1 = val
        ;; ----------------------------------------
ack:    cmp     r1, 0
        bra  nz  ack1
        add     r1, r2, 1       ; return VAL=Y+1
        ret
ack1:   PUSH    (r14)
        cmp     r2, 0
        bra  z  ack2
        sub     r3,r1,1         ; X-1
        PUSH    (r3)
        sub     r2,r2,1         ; Y-1
        jsr     ack             ; ACK(X, Y-1)
        mov     r2, r1          ; move to Y
        POP     (r1)            ; restore X
        jsr     ack
        POP     (r14)
        ret
ack2:
        sub     r1, r1, 1       ; return ACK(X-1,1)
        mov     r2, 1
        jsr     ack
        POP     (r14)
        ret

#include "include/stdio.s"

;;;  DATA Area definitions
        DATA
m1:     BSTRING "Ack(\0"
m2:     BSTRING ") = \0"
results:

        EQU     STACK_TOP,  0x0FFF
