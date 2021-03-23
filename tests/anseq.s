;;  This program prints the least significant decimal
;;  digit of Connell's sequence numbers An where
;;
;;  An = 2n - int[(1 + sqrt(8i-7))/2]
;;
;;  Translated from Martin Richards' original written
;;  in BCPL
;;
;; LET start() = VALOF
;; { LET prevd = 0
;;
;;   FOR i = 1 TO 2016 DO
;;   { LET d = (2*i - (1+sqrt(8*i-7))/2) REM 10
;;     UNLESS ((prevd NEQV d) & 1) = 0 DO newline()
;;     prevd := d
;;     writef("%n", d)
;;   }
;;   newline()
;;   RESULTIS 0
;; }

#include "options.h"
#include "macros.h"

        ORG     0x00
        EQU     MAX, 512

        movi    r12,STACK_TOP

        mov     r11, 0          ; r11 = prevd
        mov     r10, 1          ; r10 = i
        movi    r6, MAX

LOOP:   ;; LET d = (2*i - (1+sqrt(8*i-7))/2) REM 10

        asl     r9, r10, 1      ; 2*i
        asl     r8, r10, 3      ; 8*i
        sub     r1, r8, 7       ; (8*i)-7
        jsr     sqrt32          ; sqrt((8*i)-7)
        add     r1, r1, 1       ; 1 + sqrt((8*i)-7)/2
        asr     r1, r1, 1       ; (1 + sqrt((8*i)-7))/2
        sub     r1, r9, r1      ; (2*i - (1+sqrt(8*i-7))/2)
        mov     r2, 10
        jsr     udiv32          ; divide by 10 with remainder returned in r2
        mov     r7, r2          ; r7 = d
        xor     r0, r7, r11     ; prevd XOR d
        and     r0, r0, 0x1     ; & 1
        bra  z  NEXT
        PRINT_NL()
NEXT:   mov     r11, r7         ; prevd = d
        mov     r1, r7
        jsr     printdec32
        add     r10, r10, 1     ; next i
        cmp     r10, r6         ; reached MAX ?
        bra le  LOOP
        PRINT_NL()
        HALT    ()

#include "include/intmath.s"
#include "include/stdio.s"
;;;  DATA Area definitions
        DATA

m0:     BSTRING "Sqrt(\0"
m1:     BSTRING ") = \0"
results:

        EQU     STACK_TOP,      0x3F
